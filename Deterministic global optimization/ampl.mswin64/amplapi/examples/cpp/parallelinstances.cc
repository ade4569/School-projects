#include <future>
#include <iomanip>  // For std::setw and std::left
#include <iostream>
#include <mutex>
#include <numeric>
#include <sstream>
#include <string>
#include <vector>
#include <memory> // for unique_ptr
#include "ampl/ampl.h"
#include <atomic>

static std::mutex coutMutex;
static std::mutex mapMutex;
class ThreadSafeCounter {
 private:
  std::atomic<int> counter_;
  std::map<int, int> map_;

 public:
  ThreadSafeCounter() : counter_(0) {}

  // Function to read the counter (thread-safe)
  int readCounter() const {
    return counter_.load();  // Use .load() for explicit read
  }

  // Function to increment the counter (thread-safe)
  int getId(int hash) {
    std::lock_guard<std::mutex> lock(mapMutex);
    if (map_.find(hash) != map_.end())
      return map_[hash];
    else {
      counter_.fetch_add(1);
      auto myid = counter_.load();
      map_[hash] = myid;
      return myid;
    }
  }

  void printMsg(const std::string& message) {
    const int threadIdWidth = 5;
    std::lock_guard<std::mutex> lock(coutMutex);

    // Get the thread ID and convert it to a string
    std::thread::id thisThreadId = std::this_thread::get_id();
    std::size_t threadIdHash = std::hash<std::thread::id>{}(thisThreadId);
    std::string threadIdStr = std::to_string(threadIdHash);
    int id = getId(threadIdHash);

    std::stringstream prefixStream;
    prefixStream << "Thread " << std::setw(threadIdWidth) << std::left << id
                 << ": ";
    std::string prefix = prefixStream.str();

    // Use a stringstream to process the message line by line
    std::stringstream messageStream(message);
    std::string line;
    while (std::getline(messageStream, line)) {
      std::cout << prefix << line << std::endl;
    }
  }
};
static ThreadSafeCounter counter;
    // Use a thread-local storage for AMPL instances
thread_local std::unique_ptr<ampl::AMPL> localAMPL = nullptr;

void printMsg(const std::string& message) { counter.printMsg(message); }

class ThreadedOutputHandler : public ampl::OutputHandler {
  
  public:
  ampl::AMPL* myAMPL;
   void output(ampl::output::Kind kind, const char* msg) override {
     printMsg(msg);
  }
};


// Run a model with a parameter
double runModel(int i) {
  try {
    if (!localAMPL) {
      localAMPL = std::make_unique<ampl::AMPL>();
    }

    ampl::AMPL& a = *localAMPL;
    auto oh = ThreadedOutputHandler();
    oh.myAMPL = localAMPL.get();
    a.setOutputHandler(&oh);
    a.eval("param n;");
    a.eval("set A := 1..n;");
    a.eval("var x{a in A} <= a;");
    a.eval("maximize z: sum{a in A} x[a];");
    a.getParameter("n").set(i);
    a.setOption("solver", "gurobi");
    a.solve();
    double r = localAMPL->getValue("z").dbl();
    // Close and return objective value
    a.close();
    return r;
  } catch (const std::exception& e) {
    printMsg(e.what());
    return 0;
  }
}

int main(int argc, char** argv) {
  const int NTHREADS = 20;

  // Use a vector of futures to store the promised results of each thread
  std::vector<std::future<double>> futures;
  for (int i = 1; i <= NTHREADS; ++i) {
    futures.push_back(std::async(std::launch::async, [i]() {
      return runModel(i);
    }));
  }


  // Wait for all threads to finish and collect the results
  std::vector<double> results;
  for (auto& fut : futures) {
    try {
      results.push_back(fut.get());
    } catch (const std::exception& e) {
      std::cout << e.what() << "\n";
    }
  }

  // Calculate the total objective value
  double total = std::accumulate(results.begin(), results.end(), 0.0);

  // Expected result for each model is the triangular number:
  double expected = 0;
  for (int i = 1; i <= NTHREADS; i++) expected += (i * (i + 1) / 2);
  std::cout << std::endl << std::endl << "Total is " << total << std::endl;
  std::cout << "And it appears to be "
            << ((expected == total) ? "correct" : "not correct") << std::endl;

  return 0;
}