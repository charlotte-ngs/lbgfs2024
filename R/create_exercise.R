


#' Create Generic Exercise 
#'
#' @param ps_ex_name exercise name
#' @param ps_ex_tmpl_path path to exercise template
#' @param ps_ex_out_path path to created exercise file
#' @param pl_repl_data list of replacement data
#'
#' @examples
#' \dontrun{
#' create_exercise(ps_ex_name = 'lbg_sol01',
#'                 ps_ex_tmpl_path = system.file("exercises", "lbgfs2024", "templates", "lbg_ex_template.qmd", package = "lbgfs2024"),
#'                 ps_ex_out_path = system.file("exercises", "lbgfs2024", "solutions", ps_ex_name, paste0(ps_ex_name, ".qmd")),
#'                 ps_repl_data = list(course_name = "LBG - FS2024",doc_type = "Solution",ex_count = 1, author = "Peter von Rohr"))
#' }
create_exercise <- function(ps_ex_name, 
                            ps_ex_tmpl_path,
                            ps_ex_out_path,
                            pl_repl_data) {
  # checks
  if (!file.exists(ps_ex_tmpl_path))
    stop(" *** ERROR in create_exercise: CANNOT FIND template path: ", ps_ex_tmpl_path)
  
  # read template
  con_tmpl <- file(ps_ex_tmpl_path)
  vec_ex_tmpl <- readLines(con_tmpl)
  close(con_tmpl)
  
  # get yml-header
  n_yml_end <- grep('---', vec_ex_tmpl, fixed = T)[2]
  vec_yml <- vec_ex_tmpl[1:n_yml_end]
  
  # run replacement
  vec_yml_out <- whisker::whisker.render(template = vec_yml,
                                         data = pl_repl_data)
  vec_ex_out <- c(vec_yml_out, vec_ex_tmpl[(n_yml_end+1):length(vec_ex_tmpl)])

  # create output directory, if it does not yet exist  
  s_ex_out_dir <- dirname(ps_ex_out_path)
  if (!dir.exists(s_ex_out_dir)) dir.create(s_ex_out_dir, recursive = T)
  # check if output path exists, then rename
  if (file.exists(ps_ex_out_path)) 
    file.rename(ps_ex_out_path, paste0(ps_ex_out_path, format(Sys.time(), "%Y%m%d%H%M%S")))
  # write to output path
  cat(paste0(vec_ex_out, collapse = "\n"), "\n", file = ps_ex_out_path)
  
  return(invisible(NULL))
}


#' Create LBG Exercise
#'
#' @param ps_ex_name name of exercise
#' @param ps_ex_count exercise count
#'
#' @export create_exercise_lbg
#'
#' @examples
#' \dontrun{
#' create_exercise_lbg(ps_ex_name = "lbg_sol01")
#' }
create_exercise_lbg <- function(ps_ex_name, 
                                ps_ex_count = as.integer(gsub(pattern = '[[:punct:]]', 
                                                              replacement = '', 
                                                              gsub(pattern = "[[:alpha:]]+", 
                                                                   replacement = "", ps_ex_name)))){
  s_ex_tmpl_path = system.file("exercises", "lbgfs2024", "templates", "lbg_ex_template.qmd", package = "lbgfs2024")
  s_ex_out_root = system.file("exercises", "lbgfs2024", "solutions", package = "lbgfs2024")
  s_ex_out_path = file.path(s_ex_out_root, ps_ex_name, paste0(ps_ex_name, ".qmd"))
  l_repl_data = list(course_name = "LBG - FS2024", doc_type = "Solution", ex_count = ps_ex_count, author = "Peter von Rohr")
  create_exercise(ps_ex_name = ps_ex_name, 
                  ps_ex_tmpl_path = s_ex_tmpl_path,
                  ps_ex_out_path = s_ex_out_path,
                  pl_repl_data = l_repl_data)
  return(invisible(NULL))
}