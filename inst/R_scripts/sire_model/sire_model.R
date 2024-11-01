

# read the data
s_beef <- 'https://charlotte-ngs.github.io/lbgfs2024/data/small_beef_data.csv'
tbl_beef <- readr::read_delim(s_beef, delim = ",")
tbl_beef

# herd as fixed effect ==> Herd must be converted to data type factor
tbl_beef$Herd <- as.factor(tbl_beef$Herd)
tbl_beef

# design matrix X
mat_X <- model.matrix(`Weaning Weight` ~ `Breast Circumference` + Herd, data=tbl_beef)
mat_X

# design matrix Z, pretend to model sire as fixed effect without intercept
tbl_beef$Sire <- as.factor(tbl_beef$Sire)
mat_Z <- model.matrix(`Weaning Weight` ~ 0 + Sire, data = tbl_beef)
mat_Z

# lamda_s = 1
lambda_s <- 1

# coefficient matrix C(
mat_xtx <- crossprod(mat_X)
mat_xtx
mat_xtz <- crossprod(mat_X, mat_Z)
mat_xtz
mat_ztx <- crossprod(mat_Z, mat_X)
mat_ztx
mat_ztz_I_lambda <- crossprod(mat_Z) + diag(1, nrow = nlevels(tbl_beef$Sire)) * lambda_s
mat_ztz_I_lambda
mat_C <- rbind(cbind(mat_xtx, mat_xtz),cbind(mat_ztx,mat_ztz_I_lambda))
mat_C

# right hand side
vec_y <- tbl_beef$`Weaning Weight`
mat_rhs <- rbind(crossprod(mat_X, vec_y), crossprod(mat_Z, vec_y))
mat_rhs

# solutions
mat_sol <- solve(mat_C, mat_rhs)
mat_sol
