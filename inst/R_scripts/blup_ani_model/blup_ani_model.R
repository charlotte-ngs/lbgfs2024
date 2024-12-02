


s_beef_data <- "https://charlotte-ngs.github.io/lbgfs2024/data/small_beef_data.csv"
tbl_beef <- readr::read_delim(s_beef_data, delim = ",")
tbl_beef

# fixed effects as in sire model (lbg_ex05)
# convert Herd into factor
tbl_beef$Herd <- as.factor(tbl_beef$Herd)
# design matrix X
mat_X <- model.matrix(`Weaning Weight` ~ `Breast Circumference` + Herd, data = tbl_beef)
mat_X

# animals without observations are also animals without parents
# therefore, we can use method of pedigree extension
tbl_beef_ped <- tbl_beef[, c("Animal", "Sire", "Dam")]
tbl_beef_ped

# function to obtain founder animals from a pedigree
get_founder_vec <- function(ptbl_ped){
  vec_founder_sire <- setdiff(ptbl_ped$Sire, ptbl_ped$Animal)
  vec_founder_dam <- setdiff(ptbl_ped$Dam, ptbl_ped$Animal)
  vec_founder <- c(vec_founder_sire, vec_founder_dam)
  vec_founder <- vec_founder[order(vec_founder)]
  return(vec_founder)
}
vec_founder_beef <- get_founder_vec(ptbl_ped = tbl_beef_ped)
n_nr_founder <- length(vec_founder_beef)


# matrix Z
mat_Z <- cbind(matrix(0, nrow=nrow(tbl_beef), ncol=n_nr_founder), 
               diag(nrow=nrow(tbl_beef)))
mat_Z


# extend pedigree with founders
tbl_beef_ped_ext <- dplyr::bind_rows(
  tibble::tibble(Animal = vec_founder, 
                 Sire = rep(NA, n_nr_founder),
                 Dam = rep(NA, n_nr_founder)),
  tbl_beef_ped)
tbl_beef_ped_ext

# pedigree in pedigreemm
pem_beef <- pedigreemm::pedigree(sire = tbl_beef_ped_ext$Sire,
                                 dam = tbl_beef_ped_ext$Dam,
                                 label = tbl_beef_ped_ext$Animal)
pem_beef

spmat_A_inv <- pedigreemm::getAInv(ped=pem_beef)
spmat_A_inv