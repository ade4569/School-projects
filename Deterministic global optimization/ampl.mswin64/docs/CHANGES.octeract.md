# Summary of recent updates to Octeract for AMPL

## 20230103
- Updated to Octeract libraries version 4.6.0:
    * General performance improvements, including novel algorithms for MINLPs and MIQCPs
    * Greatly reduced memory footprint for large-scale and dense problems
    * Improved performance of preprocessing and presolve technique for problems with complex structure
    * Refined multi-core usage and efficiency for problems that are automatically reformulated
- Solver controls can now be passed by using the AMPL option: `octeract_options`,
  see README.octeract.txt

## 20220715
- Updated to Octeract libraries version 4.4.1

## 20220705
- Fixed packaging of subsolvers

## 20220603
- Fixed an issue whereby floating licenses were not recognized
- Fixed an issue with the `-v` command line switch

## 20211210
- Initial release by AMPL, linked against Octeract libraries version 3.6.0