#' ---
#' title: Genotypic Values in a Single-Locus Model
#' date:  2024-10-04
#' ---
#' 
#' ## Read Data
#' Data is read from a given file into a tibble. Then observations are plotted 
#' against genotypes
#' 

# read data and plot
s_geno_val<-"https://charlotte-ngs.github.io/lbgfs2024/data/geno_val_single_loc.csv"
tbl_geno_val <- readr::read_delim(s_geno_val, delim=",")
plot(tbl_geno_val$Loc_G, tbl_geno_val$y)


#' ## Filter Data
#' Data are filtered according to homozygous genotypes. The filtered result is checked with 
#' a count table or with computing the mean.

# filter on G1G1
tbl_g1g1 <- dplyr::filter(tbl_geno_val, Loc_G == 2)
# same with pipes
library(dplyr)
tbl_g1g1 <- tbl_geno_val %>% filter(Loc_G == 2)
tbl_g1g1

# check
table(tbl_g1g1$Loc_G)
mean(tbl_g1g1$y)

# filter on G2G2
tbl_g2g2 <- tbl_geno_val %>% filter(Loc_G == 0)
tbl_g2g2

# check
table(tbl_g2g2$Loc_G)
mean(tbl_g2g2$y)


#' ## Regression Using Homozygous Genotypes
#' A regression line is fit using data from homozygous genotypes. Based on the 
#' estimates of this regression, the genotypic value a can be derived.

# filter hom genotypes
tbl_hom_geno <- tbl_geno_val %>% filter(Loc_G != 1)
table(tbl_hom_geno$Loc_G)

# regression line
lm_hom_geno <- lm(y ~ Loc_G, data=tbl_hom_geno)
(smry_hom_geno <- summary(lm_hom_geno))

# estimate of parameter a 
n_est_a <- mean(abs(smry_hom_geno$coefficients[,"Estimate"]))
n_est_a


#' ## Check Result Using a Regression Line Plot
#' The regression line is plotted and compared to the zero-line

# plot regression line(
plot(tbl_geno_val$Loc_G, tbl_geno_val$y)
abline(smry_hom_geno$coefficients["(Intercept)","Estimate"],
smry_hom_geno$coefficients["Loc_G","Estimate"])
abline(0,0)


#' ## Genotypic Value d
#' The group mean of the heterozygous genotypes is used to get the genotypic value d.

# Group Mean Heterozygous
tbl_g1g2 <- tbl_geno_val %>% filter(Loc_G == 1)
tbl_g1g2

# check
table(tbl_g1g2$Loc_G)
mean(tbl_g1g2$y)

