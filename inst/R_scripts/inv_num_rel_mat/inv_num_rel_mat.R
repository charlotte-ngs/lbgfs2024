

n_nr_ani_ped <- 5
n_nr_parent <- 3
tbl_ped_simple <- tibble::tibble(Calf = c(1:n_nr_ani_ped),
                             Sire = c(NA, NA, NA, 1, 3),
                             Dam  = c(NA, NA, NA, 2, 2))

tbl_ped_simple

# num rel mat_A
ped <- pedigreemm::pedigree(sire=tbl_ped_simple$Sire,
                            dam = tbl_ped_simple$Dam,
                            label = tbl_ped_simple$Calf)
ped

# mat_A
(mat_A <- as.matrix(pedigreemm::getA(ped = ped)))

# inbreeding
pedigreemm::inbreeding(ped)

# use solve
solve(mat_A)
