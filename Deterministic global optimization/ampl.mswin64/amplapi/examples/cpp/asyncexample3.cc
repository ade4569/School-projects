#include <atomic>  // for std::atomic
#include <condition_variable>
#include <iostream>
#include <memory>
#include <thread>
#include <vector>

#include "ampl/ampl.h"

namespace chrono = std::chrono;

/*
 * Class used as an output handler. It prints the AMPL output prefixed by the
 * instance id
 */
class MyOutputHandler : public ampl::OutputHandler {
  int id_;

 public:
  MyOutputHandler(int id) : id_(id) {}
  void output(ampl::output::Kind kind, const char* output) override {
    std::cout << "[" << id_ << "]: " << output << "\n";
  }
};

/*
 * Communicates the end of a solution process; it also has a reference to the
 * id of the AMPL instance it belongs to and to AMPLServices for synchronization
 */
class MyInterpretIsOver : public ampl::Runnable {
  int id_;
  class AMPLServices& services_;

 public:
  MyInterpretIsOver(int id, AMPLServices& services)
      : id_(id), services_(services) {}
  void run() override;
};

// Class to wrap AMPL (very naive but makes code more compact)
class AMPLwrapper : public ampl::AMPL {
  MyOutputHandler oh_;
  MyInterpretIsOver cb_;

 public:
  AMPLwrapper(int id, AMPLServices& services)
      : oh_(id), cb_(id, services) {
    setOutputHandler(&oh_);
  }
  void evalAsync(const char* statements) {
    ampl::AMPL::evalAsync(statements, &cb_);
  }
  void solveAsync() {
    ampl::AMPL::solveAsync(&cb_);
  }
};

// Class to store all the AMPL objects and make sure they are destructed
// when it is deleted. Can be extended to create AMPL instances "on demand".
// It also provides basic synchronization primitives.
class AMPLServices {
  std::vector<std::unique_ptr<AMPLwrapper>> ampls_;
  std::condition_variable isdone_cv_;
  std::mutex isdone_mutex_;
  std::atomic<bool> isdone_{false};

 public:
  AMPLwrapper& operator[](int n) { return *ampls_.at(n); }
  const AMPLwrapper& operator[](int n) const { return *ampls_.at(n); }

  std::size_t size() const { return ampls_.size(); }

  AMPLServices(int n) {
    for (int i = 0; i < n; i++) {
      ampls_.emplace_back(std::make_unique<AMPLwrapper>(i, *this));
    }
  }
  /**
  * Wait until any thread notifies it has finished some work (aka until a callback
  * has been called after evalAsync or solveAsync
  */
  void waitForOne() {
    std::unique_lock<std::mutex> lk(isdone_mutex_);
    isdone_cv_.wait(lk, [this] { return isdone_.load(); });
  }
  /**
   * Notify that a job has been completed
   */
  void notifyDone() {
    {
      std::lock_guard<std::mutex> lk(isdone_mutex_);
      isdone_ = true;
    }
    isdone_cv_.notify_all();
  }
  /**
  * Notify that a job hs been started
  */
  void beginWork()
  {
    std::lock_guard<std::mutex> lk(isdone_mutex_);
    isdone_ = false;
  }
};


/**
* Implementation of the callback function, prints on screen and notifies
* the AMPLService instance that a job has been completed
*/
void MyInterpretIsOver::run() {
  std::cout << "[" << id_
            << "]: Solution process ended, notifying waiting thread.\n";
  services_.notifyDone();
}

int main(int argc, char** argv) {
  std::string model =
      "set I := 1..10000;"
      "set D := 1..50;"
      "var x{I} integer >= 0;"
      "param v{i in I} := 1 + Irand224() mod 200;"
      "param w{i in I, d in D} := 1 + Irand224() mod 200;"
      "maximize profit : sum{i in I} v[i] * x[i];"
      "s.t.capacity{d in D} : sum{i in I} w[i, d] * x[i] <= 1000;"
      "option solver gurobi;"
      "option gurobi_options 'outlev=1';";

   // Create the wrapper objects, that automatically initialize callbacks and
  // output handlers
  int NINSTANCES = 3;
  AMPLServices services(NINSTANCES);

  std::cout << "Ready to start\n";
  for (int i = 1; i < 3; i++) {
    services.beginWork();
    std::cout << "\n\nIteration " << i << std::endl;
    // Reset all instances
    for (int i = 0; i < NINSTANCES; i++) services[i].reset();

    services[0].eval(model);
    services[0].setOption("gurobi_options", "outlev=0 timelim=10");
    std::cout << "Start first solve\n";
    services[0].solveAsync(); /* use the additional function, that
    automatically assigns the appropriate callback when calling evalAsync */

    services[1].eval(model);
    services[1].setOption("gurobi_options", "outlev=0 timelim=100");
    std::cout << "Start second solve\n";
    services[1].solveAsync();

    services[2].eval(model);
    services[2].setOption("gurobi_options", "outlev=0 timelim=5");
    std::cout << "Start third solve\n";
    services[2].solveAsync();

    std::cout << "Main thread: Waiting for any solution to end...\n";
    auto start = chrono::system_clock::now();
    services.waitForOne();

    auto duration = chrono::system_clock::now() - start;
    std::cout << "Main thread: done waiting.";
    std::cout << "Main thread: waited for "
              << chrono::duration_cast<chrono::milliseconds>(duration).count()
              << " ms\n";

    for (int i = 0; i < NINSTANCES; i++) services[i].interrupt();
    std::cout << "Interrupted all sessions." << std::endl;

    for (int i = 0; i < NINSTANCES; i++) {
      std::cout << "[" << i << "] Result: " << services[i].getValue("solve_result").str()
                << std::endl;
      std::cout << "[" << i << "] Solve time: "
                << services[i].getValue("_total_solve_time").dbl() << std::endl;
    }
  }
  return 0;
}
