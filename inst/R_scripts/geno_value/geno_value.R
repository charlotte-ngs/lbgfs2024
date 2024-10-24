

s_geno_val<-"https://charlotte-ngs.github.io/lbgfs2024/data/geno_val_single_loc.csv"
tbl_geno_val <- readr::read_delim(s_geno_val, delim=",")
plot(tbl_geno_val$Loc_G, tbl_geno_val$y)

# filter on G1G1
tbl_g1g1 <- dplyr::filter(tbl_geno_val, Loc_G == 2)
# same with pipes
library(dplyr)
tbl_g1g1 <- tbl_geno_val %>% filter(Loc_G == 2)
tbl_g1g1

# check
table(tbl_g1g1$Loc_G)
mean(tbl_g1g1$y)

tbl_g2g2 <- tbl_geno_val %>% filter(Loc_G == 0)
tbl_g2g2

# check
table(tbl_g2g2$Loc_G)
mean(tbl_g2g2$y)

# fit regression model on hom genotypes
# filter hom genotypes
tbl_hom_geno <- tbl_geno_val %>% filter(Loc_G != 1)
table(tbl_hom_geno$Loc_G)

# regression line
lm_hom_geno <- lm(y ~ Loc_G, data=tbl_hom_geno)
(smry_hom_geno <- summary(lm_hom_geno))

# estimate of parameter a 
n_est_a <- mean(abs(smry_hom_geno$coefficients[,"Estimate"]))
n_est_a


# plot regression line(
plot(tbl_geno_val$Loc_G, tbl_geno_val$y)
abline(smry_hom_geno$coefficients["(Intercept)","Estimate"],
smry_hom_geno$coefficients["Loc_G","Estimate"])
abline(0,0)


# Group Mean Heterozygous
tbl_g1g2 <- tbl_geno_val %>% filter(Loc_G == 1)
tbl_g1g2

# check
table(tbl_g1g2$Loc_G)
mean(tbl_g1g2$y)

