# Master's Thesis: 'A Likelihood Ratio Framework for Change Point Detection with Applications to Financial Time Series'

## Overview 
This report uses a likelihood ratio framework to develop methods for detecting changes in the mean and variance of a time series. We begin by considering a single change point under a univariate signal-plus-noise model and extend this to cover multiple change points and multivariate and high-dimensional data, with parallels drawn to the Bayesian paradigm. We subsequently relax the independence assumption through autoregressive and vector autoregressive models, which capture temporal and cross-sectional dependence respectively. We derive thresholds for the
limiting behaviour of the generalised log-likelihood ratio test statistic and align these with established information criteria. The methods are applied to S&P 500 returns and a portfolio of stocks during the period 2018-2022. Multiple detection algorithms consistently identify a change point in February 2020 corresponding to the onset of the COVID-19 pandemic, with INSPECT identifying airline, energy, and financial
stocks as the drivers of this change, consistent with the impact of travel restrictions, the oil price crash, and financial uncertainty during the pandemic.

## Supplementary Poster and Presentation
Poster and presentation created in the early stages of the project to highlight learnings so far. 
Explanation of model assumptions and three heuristic methods for detecting multiple changes, with application to 'Nile River' and 'UK Driver Deaths' datasets. 
### Poster
<img width="2000" height="1411" alt="image" src="https://github.com/user-attachments/assets/05e16fcb-3834-4530-b8a5-e1e3a85931a1"/>

See `thesis/Methods Poster.pdf`
### Presentation 
See `thesis/Methods Presentation.pdf`.
Also created animations for ease of explanation. 
* Sliding Window:
<img width="600"  alt="slidingwindow" src="https://github.com/user-attachments/assets/62376744-eb38-499c-9253-4f012e0f654f"/>

* Bottom Up:
<img width="600" alt="bottomup" src="https://github.com/user-attachments/assets/ac850c45-f341-495e-8c48-16ef9ce52390"/>

## Methodology 

This project implements the following from scratch:
* CUSUM Statistic 
* Binary Segmentation (BinSeg)
* Bottom-Up 
* Sliding Window
* Bayesian Change Point Detection

Plots are produced in each to demonstrate an example, typically highlighting the pros/cons of that particular change point detection method and the importance of careful threshold selection. 

The methods discussed are then applied to S&P500 data and a portfolio of stocks (`scripts/analysis`). 

## Repository Structure 
* `src/methods` : Core implementation (e.g. `binary_segmentation.R`)
* `src/utils` : Helper functions for data loading, preprocessing, generating plots
* `scripts/analysis` : Standalone scripts for S&P application (`data_application_snp.R`) and stock portfolio application (`data_application_mixed.R`)
* `thesis/` : Full PDF thesis, all visualisations, poster and presentation. 

## Reproducing the Analysis
A WRDS subscription is required to reproduce the analysis. All core implementation can be run without WRDS. Alternatively press enter when prompted for username and password and Yahoo Finance data will be used. 

1. Run `src/utils/load_data.R` to load required datasets. 
2. Check that `data/mixed_data.csv` and `data/snp_data.csv` have been created.
3. Now able to run both scripts in `scripts/analysis`.

## Summary 
### S&P500 Data
* All four change point algorithms (PELT, Binary Segmentation, Bottom-up, Sliding Window) successfully detected the initial COVID-19 market shock on Feb 21, 2020.
* PELT, bottom-up and binary segmentation all detected a second change within one day of 22 April 2020, which
follows immediately after ‘the fall of WTI crude oil futures by more than 300%’ on 20 April.  We note that the binary segmentation algorithm produced identical results to PELT, highlighting its strength in accurately detecting global changes. Sliding Window required tuning of parameters $\eta$ and $h$. 

<img width="866" height="473" alt="Screenshot 2026-09-18 at 20 06 56" src="https://github.com/user-attachments/assets/10578478-bd4a-4e00-8764-88c495721f53" />

<img width="896" height="383" alt="Screenshot 2026-09-18 at 20 09 12" src="https://github.com/user-attachments/assets/2e2b1dd8-8005-48a2-bf8a-7726abcb1d99" />

### Stock Portfolio Data
#### Inspect:

<img width="872" height="337" alt="Screenshot 2026-09-18 at 20 07 45" src="https://github.com/user-attachments/assets/9f7c00a6-5629-4b1e-a563-33098bb4d0ac" />

* Utilising wild binary segmentation within
the ‘inspect’ function and a threshold c= 10 ln(13 ln(n)) resulted in detection of two change
points. The first change point (20 February 2020) aligns with
the findings of the univariate S&P 500 data, and the second aligns with the ‘worst one day
sell-off’ of U.S. stocks since March 2020 amid growing concerns of a second wave of coronavirus.
* The elements of the sparse projection vector and their corresponding weights show the airline, energy and financials breaking
simultaneously and accounting for 95% of the projection vector, whereas other sectors such
as technology and consumer staples had negligible weights. This is again consistent with the
context of the pandemic, as travel restrictions and economic uncertainty affect these changing
stocks significantly more than those with negligible weights.

#### VAR Model:
<img width="820" height="622" alt="Screenshot 2026-09-18 at 20 12 27" src="https://github.com/user-attachments/assets/747cd74f-4e5e-4239-bd48-11f48282c400" />

* Stocks in the same sector remain correlated (for example CVX and XOM), but between-sector correlations become considerably weaker.
This is consistent with the heterogeneous impact of the pandemic across sectors, so that sectors
that previously moved together diverged.
* This finding aligns with the INSPECT weightings,
which indicated some sectors (airlines, energy, financials) were more severely impacted than
others (technology, consumer staples).


