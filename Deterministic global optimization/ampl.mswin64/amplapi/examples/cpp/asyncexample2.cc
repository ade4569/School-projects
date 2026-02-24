#include <condition_variable>
#include <iostream>
#include <thread>
#include <memory> // for std::unique_ptr

#include "ampl/ampl.h"


// Shows how to start various AMPL instances asynchronously (with different solver time limits) 
// and interrupt all the instances when any process returns

namespace chrono = std::chrono;

// Use C++11 synchronization:
std::condition_variable isdone_cv;
std::mutex isdone_mutex;
bool isdone = false;
struct IsDone {
  bool operator()() const { return isdone; }
};

/*
 * Class used as an output handler. It prints the AMPL output prefixed by the instance id
 */
class MyOutputHandler : public ampl::OutputHandler {
  int id_;
 public:
  MyOutputHandler(int id) : id_(id) {}
  void output(ampl::output::Kind kind, const char *output) {
    std::cout << "[" << id_ << "]: " << output << "\n";
  }
};

/*
 * Communicates the end of a solution process; it also has a reference to the 
 * id of the AMPL instance it belongs to
 */
class MyInterpretIsOver : public ampl::Runnable {
  int id_;
 public:
  MyInterpretIsOver(int id) : id_(id) {}
  void run() {
    std::cout << "[" << id_
              << "]: Solution process ended, notifying waiting thread.\n";
    {
      std::lock_guard<std::mutex> lk(isdone_mutex);
      isdone = true;
    }
    isdone_cv.notify_all();
  }
};


int main(int argc, char **argv) {
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
  
  try {
    // Create the AMPL objects and their output handlers
    ampl::AMPL a1, a2;
    MyOutputHandler oh1(1);
    MyOutputHandler oh2(2);
    a1.setOutputHandler(&oh1);
    a2.setOutputHandler(&oh2);

    // Create the callback objects to be used when calling async functions
    MyInterpretIsOver callback(1);
    MyInterpretIsOver callback2(2);

    std::cout << "Ready to start\n";

    // Execute multiple times to test stability of initialization and
    // destruction
    for (int i = 1; i < 3; i++) {
      // Set variable to false, meaning we will wait for an AMPL process to
      // communicate it finished
      isdone = false;
      std::cout << "\n\nIteration " << i << std::endl;
      a1.reset();
      a2.reset();
      // First instance
      a1.eval(model);
      a1.setOption("gurobi_options", "outlev=0 timelim=5");
      std::cout << "Start first solve\n";
      a1.solveAsync(&callback);
      // second instance
      a2.eval(model);
      a2.setOption("gurobi_options", "outlev=0 timelim=100");
      std::cout << "Start second solve\n";
      a2.solveAsync(&callback2);

      std::cout << "Main thread: Waiting for solution to end...\n";

      auto start = chrono::system_clock::now();
      {
        // Wait for the condition variable to be notified that a solution
        // process has ended
        std::unique_lock<std::mutex> lk(isdone_mutex);
        isdone_cv.wait(lk, IsDone());
      }
      auto duration = chrono::system_clock::now() - start;
      std::cout << "Main thread: done waiting.";
      std::cout << "Main thread: waited for "
                << chrono::duration_cast<chrono::milliseconds>(duration).count()
                << " ms\n";

      // Interrupt both running instances
      a1.interrupt();
      a2.interrupt();
      std::cout << "Interrupted both sessions.";
      a1.eval("display _total_solve_time;");
      a2.eval("display _total_solve_time;");
    }

  } catch (const std::exception &e) {
    std::cout << e.what() << std::endl;
  }
  return 0;
}
