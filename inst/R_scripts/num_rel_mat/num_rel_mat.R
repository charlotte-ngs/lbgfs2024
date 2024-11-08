


tbl_ped <- tibble::tibble(Animal = 3:6, 
                                  Sire = c(1,NA,4,5),
                                  Dam = c(2,NA,3,2))
tbl_ped

# extend pedigree by founders
vec_founder_sire <- setdiff(tbl_ped$Sire, tbl_ped$Animal)
vec_founder_dam <- setdiff(tbl_ped$Dam, tbl_ped$Animal)
vec_founder <- c(vec_founder_sire, vec_founder_dam)
vec_founder <- vec_founder[order(vec_founder)]
vec_founder <- vec_founder[!is.na(vec_founder)]
vec_founder

n_nr_founder <- length(vec_founder)
tbl_ped_founder <- tibble::tibble(Animal = vec_founder,
                                  Sire = rep(NA, n_nr_founder),
                                  Dam = rep(NA, n_nr_founder))
tbl_ped_founder

# extended pedigree
tbl_ped_ext <- dplyr::bind_rows(tbl_ped_founder, tbl_ped)
tbl_ped_ext