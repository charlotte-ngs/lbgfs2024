

n_nr_ani_ped <- 6
n_nr_parent <- 2

tbl_ped <- tibble::tibble(Calf = c((n_nr_parent+1):n_nr_ani_ped),
                             Sire = c(1, 1, 4, 5),
                             Dam  = c(2, NA, 3, 2))
tbl_ped


tbl_ped_extended <- tibble::tibble(Animal = c(1:n_nr_ani_ped),
                                      Sire = c(NA, NA, 1, 1, 4, 5),
                                      Dam  = c(NA, NA, 2, NA, 3, 2))
tbl_ped_extended

# pedigreemm
ped <- pedigreemm::pedigree(sire = tbl_ped_extended$Sire,
                            dam = tbl_ped_extended$Dam,
                            label = tbl_ped_extended$Animal)
ped

# numerator relationship matrix
mat_A <- as.matrix(pedigreemm::getA(ped = ped))
mat_A

# inbreeding
diag(mat_A) - 1
pedigreemm::inbreeding(ped=ped)

