Octeract is a deterministic Global Optimisation (DGO) solver which 
solves general nonlinear problems to guaranteed global optimality.

See https://octeract.gg/docs/ for an up-to-date documentation.

Options can be specified in a space separated string via the AMPL 
statement:

ampl: option octeract_options "option string";

For example:

option octeract_options "CP_MAX_ITERATIONS=10 USE_REFORMULATION_LINEARIZATION=false";

The list of options can be found at:
https://octeract.gg/docs/octeract-engine-options/options-reference/

