#' Predict from a workflow
#'
#' @description
#' This is the `predict()` method for a fit workflow object. The nice thing
#' about predicting from a workflow is that it will:
#'
#' - Preprocess `new_data` using the preprocessing method specified when the
#'   workflow was created and fit. This is accomplished using
#'   [hardhat::forge()], which will apply any formula preprocessing or call
#'   [recipes::bake()] if a recipe was supplied.
#'
#' - Call [parsnip::predict.model_fit()] for you using the underlying fit
#'   parsnip model.
#'
#' @inheritParams parsnip::predict.model_fit
#'
#' @param object A workflow that has been fit by [fit.workflow()]
#'
#' @param new_data A data frame containing the new predictors to preprocess
#'   and predict on
#'
#' @param outcomes A logical. Should the outcomes be processed and returned as well?
#'
#' @return
#' A data frame of model predictions, with as many rows as `new_data` has.
#'
#' @name predict-workflow
#' @export
#' @examples
#' library(parsnip)
#' library(recipes)
#'
#' training <- mtcars[1:20,]
#' testing <- mtcars[21:32,]
#'
#' model <- linear_reg()
#' model <- set_engine(model, "lm")
#'
#' workflow <- workflow()
#' workflow <- add_model(workflow, model)
#'
#' recipe <- recipe(mpg ~ cyl + disp, training)
#' recipe <- step_log(recipe, disp)
#'
#' workflow <- add_recipe(workflow, recipe)
#'
#' fit_workflow <- fit(workflow, training)
#'
#' # This will automatically `bake()` the recipe on `testing`,
#' # applying the log step to `disp`, and then fit the regression.
#' predict(fit_workflow, testing)
predict.workflow <- function(object, new_data, type = NULL, opts = list(), outcomes = FALSE, ...) {
  workflow <- object

  if (!workflow$trained) {
    abort("Workflow has not yet been trained. Do you need to call `fit()`?")
  }

  blueprint <- workflow$pre$mold$blueprint
  forged <- hardhat::forge(new_data, blueprint, outcomes = outcomes)
  new_data <- forged$predictors

  fit <- workflow$fit$fit

  predict_df <- predict(fit, new_data, type = type, opts = opts, ...)

  if(outcomes) {
    predict_df <- cbind(predict_df, forged$outcomes)
  }

  predict_df
}
