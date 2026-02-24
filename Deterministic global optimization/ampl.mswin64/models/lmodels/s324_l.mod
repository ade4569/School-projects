# s324.mod	QQR2-AN-2-3
# Original AMPL coding by Elena Bobrovnikova (summer 1996 at Bell Labs).

# Ref.: K. Schittkowski, More Test Examples for Nonlinear Programming Codes.
# Lecture Notes in Economics and Mathematical Systems, v. 282,
# Springer-Verlag, New York, 1987, p. 145.

# Number of variables:  2
# Number of constraints:  3
# Objective convex separable quadratic
# Quadratic constraints

param x1_l := 2;
param x1_u := 1000;
param x2_l := 0;
param x2_u := 1000;

var x{1..2} := 2;
var y{1..3} := 2;


minimize Obj:
         0.01 * y[1] + y[2];

s.t. G1:
     y[3] - 25 >= 0;
s.t. G2:
     y[1] + y[2] - 25 >= 0;
s.t. B1:
     x[1] >= x1_l;
s.t. B2:
     x[2] >= x2_l;
s.t. B3:
     x[1] <= x1_u;
s.t. B4:
     x[2] <= x2_u;

# Linearisation de x1*x2
s.t. L1:
     y[3] >= x1_l * x[2] + x2_l * x[1] - x1_l * x2_l;
s.t. L2:
     y[3] >= x1_u * x[2] + x2_u * x[1] - x1_u * x2_u;
s.t. L3:
     y[3] <= x1_l * x[2] + x2_u * x[1] - x1_l * x2_u;
s.t. L4:
     y[3] <= x1_u * x[2] + x2_l * x[1] - x1_u * x2_l; 

# Linearisation de x1^2
s.t. L5:
     y[1] >= 2 * x1_l * x[1] - x1_l^2;
s.t. L6:
     y[1] >= 2 * x1_u * x[1] - x1_u^2;
s.t. L7:
     y[1] <= (x1_l + x1_u) * x[1] - x1_l * x1_u;

# Linearisation de x2^2
s.t. L8:
     y[2] >= 2 * x2_l * x[2] - x2_l^2;
s.t. L9:
     y[2] >= 2 * x2_u * x[2] - x2_u^2;
s.t. L10:
     y[2] <= (x2_l + x2_u) * x[2] - x2_l * x2_u;
