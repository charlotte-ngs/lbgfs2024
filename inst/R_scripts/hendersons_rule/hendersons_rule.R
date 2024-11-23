

n_nr_founder <- 3
tbl_ped <- tibble::tibble(Animal = c(1:n_nr_founder),
                          Sire = rep(NA, n_nr_founder),
                          Dam = rep(NA, n_nr_founder))
pem_ped <- pedigreemm::pedigree(sire = tbl_ped$Sire,
                                dam = tbl_ped$Dam,
                                label = tbl_ped$Animal)
pem_ped

# matrix D
pedigreemm::Dmat(ped=pem_ped)

# inverse of D
mat_D_inv <- diag(1/pedigreemm::Dmat(ped=pem_ped))
mat_D_inv

# invers of L = I - P for animals without parents P = 0
mat_L_inv <- diag(nrow=n_nr_founder)
mat_L_inv

# Ainv
A_inv <- t(mat_L_inv) %*% mat_D_inv %*% mat_L_inv
A_inv

# animal 1 as parent of animal 3
tbl_ped$Sire[3] <- 1
tbl_ped
pem_ped <- pedigreemm::pedigree(sire = tbl_ped$Sire,
                                dam = tbl_ped$Dam,
                                label = tbl_ped$Animal)
pem_ped

# inverse of D
mat_D_inv <- diag(1/pedigreemm::Dmat(ped=pem_ped))
mat_D_inv

# inverse of L
mat_P <- matrix(0,nrow=nrow(tbl_ped), ncol=nrow(tbl_ped))
mat_P[3,1] <- 0.5
mat_P
mat_L_inv <- diag(nrow=nrow(tbl_ped)) - mat_P
mat_L_inv


# function to get L_inv
get_L_inv <- function(ptbl_ped){
  # number of animals in pedigree
  n_nr_ani <- nrow(ptbl_ped)
  # init result matrix
  mat_L_inv_result <- diag(nrow=n_nr_ani)
  # loop over rows of pedigree
  for (idx in 1:n_nr_ani){
    s_idx <- ptbl_ped$Sire[idx]
    if (!is.na(s_idx)) {
      mat_L_inv_result[idx,s_idx] <- -0.5
    }
    d_idx <- ptbl_ped$Dam[idx]
    if (!is.na(d_idx)){
      mat_L_inv_result[idx,d_idx] <- -0.5
    }
  }
  return(mat_L_inv_result)
}

mat_L_inv <- get_L_inv(ptbl_ped = tbl_ped)
mat_L_inv

