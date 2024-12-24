
rm(list = ls())
b_online <- TRUE
if (b_online){
  s_data_root <- "https://charlotte-ngs.github.io/lbgfs2024/data"
} else {
  s_data_root <- file.path(here::here(), "docs", "data")
}

s_mat_p2 <- file.path(s_data_root, "exam_inv_num_rel_mat_p2.csv")
tbl_mat_p2 <- readr::read_delim(s_mat_p2, delim = ",")
tbl_mat_p2

mat_A_inv <- as.matrix(tbl_mat_p2)
mat_A_inv


################################## ###
# use the way via mat_A
mat_A <- solve(mat_A_inv)
mat_A

# chol decomposition
mat_R <- t(chol(mat_A))
mat_R

# decompose
mat_S <- diag(diag(mat_R), nrow = nrow(mat_R))
mat_S

mat_L <- mat_R %*% solve(mat_S)
mat_L

# parent-offspring 
mat_P <- diag(nrow(mat_L)) - solve(mat_L)
round(mat_P, digits = 8)

# decomposition of mat_A_inv
mat_Q <- t(chol(mat_A_inv))
mat_Q

round(mat_Q %*% t(mat_Q) - mat_A_inv, digits = 8)

round(t(solve(mat_R)) %*% solve(mat_R) - mat_A_inv, digits = 8)



