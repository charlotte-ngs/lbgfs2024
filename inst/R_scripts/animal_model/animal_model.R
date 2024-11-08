

# read the data
s_beef <- 'https://charlotte-ngs.github.io/lbgfs2024/data/small_beef_data.csv'
tbl_beef <- readr::read_delim(s_beef, delim = ",")
tbl_beef

vec_founder_sire <- setdiff(tbl_beef$Sire, tbl_beef$Animal)
vec_founder_sire

vec_founder_dam <- setdiff(tbl_beef$Dam, tbl_beef$Animal)
vec_founder_dam

vec_founder <- c(vec_founder_sire, vec_founder_dam)
vec_founder <- vec_founder[order(vec_founder)]
vec_founder
n_nr_founder <- length(vec_founder)
n_nr_founder

# first block of matrix Z
mat_Z_founders <- matrix(0, nrow = nrow(tbl_beef), ncol = n_nr_founder)
mat_Z_founders

# second block of matrix Z
mat_Z_records <- diag(1, nrow = nrow(tbl_beef))
mat_Z_records

# complete matrix Z
mat_Z <- cbind(mat_Z_founders, mat_Z_records)
mat_Z

# matrix X is the same as in the sire model
tbl_beef$Herd <- as.factor(tbl_beef$Herd)
mat_X <- model.matrix(`Weaning Weight` ~ `Breast Circumference` + Herd, data = tbl_beef)
mat_X