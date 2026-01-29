# Commencement Example

*Built with R 4.5.2*

------------------------------------------------------------------------

This example uses the `Receptiviti` API to analyze commencement
speeches.

## Data

We’ll start by collecting and processing the speeches.

### Collection

The speeches used to be provided more directly, but the service hosting
them has since shut down.

They are still available in a slightly less convenient form, as the
source of a site that displays them:
[whatrocks.github.io/commencement-db](https://whatrocks.github.io/commencement-db).

First, we can retrieve metadata from a separate repository:

``` r
speeches <- read.csv(paste0(
  "https://raw.githubusercontent.com/whatrocks/markov-commencement-speech",
  "/refs/heads/master/speech_metadata.csv"
))

library(knitr)
kable(speeches[1:5, 2:4])
```

| name             | school                 | year |
|:-----------------|:-----------------------|-----:|
| Aaron Sorkin     | Syracuse University    | 2012 |
| Abigail Washburn | Colorado College       | 2012 |
| Adam Savage      | Sarah Lawrence College | 2012 |
| Adrienne Rich    | Douglass College       | 1977 |
| Ahmed Zewail     | Caltech                | 2011 |

One file in the source repository contains an invalid character on
Windows (`:`), so we’ll need to pull them in individually, rather than
cloning the repository:

``` r
text_dir <- "../../commencement_speeches/"
dir.create(text_dir, FALSE)

text_url <- paste0(
  "https://raw.githubusercontent.com/whatrocks/commencement-db",
  "/refs/heads/master/src/pages/"
)
for (file in speeches$filename) {
  out_file <- paste0(text_dir, sub(":", "", file, fixed = TRUE))
  if (!file.exists(out_file)) {
    text <- readLines(paste0(
      text_url, sub(".txt", "/index.md", file, fixed = TRUE)
    ), warn = FALSE)
    writeLines(
      text[-seq_len(max(grep("^---", text)) + 1)],
      out_file
    )
  }
}
```

### Text Preparation

Now we can read in the texts and associate them with their metadata:

``` r
speeches$text <- vapply(speeches$filename, function(file) {
  paste(readLines(paste0(
    text_dir, sub(":", "", file, fixed = TRUE)
  ), warn = FALSE), collapse = " ")
}, "")
```

The texts contain a few special characters, which we can replace:

``` r
# general special character replacement
library(lingmatch)
clean <- lma_dict(special, as.function = gsub)
speeches$text <- clean(speeches$text)

# ensure list items are treated as separate sentences
speeches$text <- gsub("([a-z]) •", "\\1. ", speeches$text)
```

## Load Package

If this is your first time using the package, see the [Get
Started](https://receptiviti.github.io/receptiviti-r/articles/receptiviti.html)
guide to install it and set up your API credentials.

``` r
library(receptiviti)
```

## Analyze Full Texts

We might start by seeing if any speeches stand out in terms of language
style, or if there are any trends in content over time.

### Full: Process Text

Now we can send the texts to the API for scoring, and join the results
we get to the metadata:

``` r
# since our texts are from speeches,
# it might make sense to use the spoken norming context
processed <- receptiviti(speeches$text, version = "v2", context = "spoken")
processed <- cbind(speeches[, 1:4], processed)

kable(processed[1:5, -(1:7)], digits = 3, row.names = FALSE)
```

| summary.words_per_sentence | summary.sentence_count | summary.six_plus_words | summary.capitals | summary.emojis | summary.emoticons | summary.hashtags | summary.urls | big_5.extraversion | big_5.active | big_5.assertive | big_5.cheerful | big_5.energetic | big_5.friendly | big_5.sociable | big_5.openness | big_5.adventurous | big_5.artistic | big_5.emotionally_aware | big_5.imaginative | big_5.intellectual | big_5.liberal | big_5.conscientiousness | big_5.ambitious | big_5.cautious | big_5.disciplined | big_5.dutiful | big_5.organized | big_5.self_assured | big_5.neuroticism | big_5.aggressive | big_5.anxiety_prone | big_5.impulsive | big_5.melancholy | big_5.self_conscious | big_5.stress_prone | big_5.agreeableness | big_5.cooperative | big_5.empathetic | big_5.genuine | big_5.generous | big_5.humble | big_5.trusting | social_dynamics.social | social_dynamics.affiliation | social_dynamics.inward_focus | social_dynamics.outward_focus | social_dynamics.authentic | social_dynamics.negations | social_dynamics.clout | drives.affiliation | drives.achievement | drives.risk_seeking | drives.risk_aversion | drives.risk_focus | drives.power | drives.reward | cognition.analytical_thinking | cognition.cognitive_processes | cognition.causation | cognition.certainty | cognition.comparisons | cognition.differentiation | cognition.discrepancies | cognition.insight | cognition.tentative | temporal_and_orientation.focus_past | temporal_and_orientation.focus_present | temporal_and_orientation.focus_future | temporal_and_orientation.self_focus | temporal_and_orientation.external_focus | sallee.sentiment | sallee.goodfeel | sallee.badfeel | sallee.emotionality | sallee.non_emotion | sallee.ambifeel | sallee.admiration | sallee.amusement | sallee.excitement | sallee.gratitude | sallee.joy | sallee.love | sallee.anger | sallee.boredom | sallee.disgust | sallee.fear | sallee.sadness | sallee.calmness | sallee.curiosity | sallee.surprise | sparse_sallee.sentiment | sparse_sallee.goodfeel | sparse_sallee.badfeel | sparse_sallee.emotionality | sparse_sallee.non_emotion | sparse_sallee.ambifeel | sparse_sallee.admiration | sparse_sallee.amusement | sparse_sallee.excitement | sparse_sallee.gratitude | sparse_sallee.joy | sparse_sallee.love | sparse_sallee.anger | sparse_sallee.boredom | sparse_sallee.disgust | sparse_sallee.fear | sparse_sallee.sadness | sparse_sallee.calmness | sparse_sallee.curiosity | sparse_sallee.surprise | liwc15.analytical_thinking | liwc15.clout | liwc15.authentic | liwc15.emotional_tone | liwc15.six_plus_words | liwc15.dictionary_words | liwc15.function_words | liwc15.pronouns | liwc15.personal_pronouns | liwc15.i | liwc15.we | liwc15.you | liwc15.she_he | liwc15.they | liwc15.impersonal_pronouns | liwc15.articles | liwc15.prepositions | liwc15.auxiliary_verbs | liwc15.adverbs | liwc15.conjunctions | liwc15.negations | liwc15.other_grammar | liwc15.verbs | liwc15.adjectives | liwc15.comparisons | liwc15.interrogatives | liwc15.numbers | liwc15.quantifiers | liwc15.affective_processes | liwc15.positive_emotion_words | liwc15.negative_emotion_words | liwc15.anxiety_words | liwc15.anger_words | liwc15.sad_words | liwc15.social_processes | liwc15.family | liwc15.friends | liwc15.female | liwc15.male | liwc15.cognitive_processes | liwc15.insight | liwc15.causation | liwc15.discrepancies | liwc15.tentative | liwc15.certainty | liwc15.differentiation | liwc15.perceptual_processes | liwc15.see | liwc15.hear | liwc15.feel | liwc15.biological_processes | liwc15.body | liwc15.health | liwc15.sexual | liwc15.ingestion | liwc15.drives | liwc15.affiliation | liwc15.achievement | liwc15.power | liwc15.reward | liwc15.risk | liwc15.time_orientation | liwc15.focus_past | liwc15.focus_present | liwc15.focus_future | liwc15.relativity | liwc15.motion | liwc15.space | liwc15.time | liwc15.personal_concerns | liwc15.work | liwc15.leisure | liwc15.home | liwc15.money | liwc15.religion | liwc15.death | liwc15.informal_language | liwc15.swear_words | liwc15.netspeak | liwc15.assent | liwc15.nonfluencies | liwc15.filler_words | liwc15.all_punctuation | liwc15.periods | liwc15.commas | liwc15.colons | liwc15.semicolons | liwc15.question_marks | liwc15.exclamations | liwc15.dashes | liwc15.quotes | liwc15.apostrophes | liwc15.parentheses | liwc15.other_punctuation | disc_dimensions.bold_assertive_outgoing | disc_dimensions.calm_methodical_reserved | disc_dimensions.people_relationship_emotion_focus | disc_dimensions.task_system_object_focus | disc_dimensions.d_axis | disc_dimensions.i_axis | disc_dimensions.s_axis | disc_dimensions.c_axis | disc_dimensions.d_axis_proportional | disc_dimensions.i_axis_proportional | disc_dimensions.s_axis_proportional | disc_dimensions.c_axis_proportional |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 19.522 | 134 | 0.192 | 0.030 | 0 | 0 | 0.000 | 0 | 64.363 | 58.626 | 58.353 | 49.845 | 71.487 | 58.030 | 68.059 | 50.421 | 49.369 | 52.583 | 66.630 | 67.808 | 35.576 | 44.799 | 61.610 | 53.635 | 60.639 | 47.382 | 71.734 | 56.499 | 48.378 | 59.538 | 65.811 | 52.359 | 37.228 | 61.668 | 42.196 | 50.852 | 59.861 | 41.189 | 48.178 | 72.834 | 62.701 | 47.853 | 53.700 | 60.770 | 45.872 | 55.720 | 57.613 | 59.304 | 45.660 | 58.078 | 45.872 | 49.981 | 63.550 | 55.012 | 55.934 | 46.702 | 50.347 | 50.226 | 38.625 | 49.536 | 44.840 | 48.413 | 38.166 | 46.326 | 45.965 | 35.126 | 0.060 | 0.092 | 0.021 | 0.045 | 0.072 | 0.028 | 0.113 | 0.085 | 0.226 | 0.774 | 0.028 | 0.036 | 0.008 | 0.014 | 0.018 | 0.017 | 0.034 | 0.044 | 0.014 | 0.018 | 0.024 | 0.024 | 0.007 | 0.005 | 0.000 | -0.012 | 0.022 | 0.034 | 0.060 | 0.940 | 0.003 | 0.005 | 0.002 | 0.003 | 0.005 | 0.003 | 0.007 | 0.015 | 0.013 | 0.013 | 0.011 | 0.000 | 0.000 | 0.002 | 0 | 0.510 | 0.811 | 0.575 | 0.590 | 0.192 | 0.924 | 0.544 | 0.172 | 0.117 | 0.045 | 0.010 | 0.041 | 0.010 | 0.011 | 0.055 | 0.073 | 0.123 | 0.097 | 0.048 | 0.072 | 0.013 | 0.281 | 0.185 | 0.037 | 0.024 | 0.021 | 0.024 | 0.021 | 0.048 | 0.033 | 0.015 | 0.003 | 0.006 | 0.003 | 0.123 | 0.006 | 0.005 | 0.006 | 0.011 | 0.097 | 0.024 | 0.016 | 0.014 | 0.017 | 0.012 | 0.023 | 0.021 | 0.008 | 0.007 | 0.005 | 0.019 | 0.001 | 0.013 | 0.002 | 0.002 | 0.073 | 0.023 | 0.016 | 0.021 | 0.017 | 0.006 | 0.173 | 0.060 | 0.092 | 0.021 | 0.153 | 0.023 | 0.063 | 0.070 | 0.070 | 0.039 | 0.018 | 0.005 | 0.004 | 0.002 | 0.003 | 0.006 | 0.004 | 0.000 | 0.000 | 0.002 | 0.000 | 0.173 | 0.050 | 0.063 | 0.002 | 0.002 | 0.001 | 0.000 | 0.008 | 0.012 | 0.032 | 0.000 | 0.002 | 56.553 | 43.447 | 68.786 | 48.847 | 52.559 | 62.371 | 54.667 | 46.068 | 0.244 | 0.289 | 0.253 | 0.214 |
| 28.587 | 109 | 0.246 | 0.032 | 0 | 0 | 0.001 | 0 | 55.126 | 61.659 | 58.563 | 43.088 | 54.867 | 52.055 | 57.030 | 71.208 | 38.108 | 68.145 | 61.884 | 85.177 | 52.581 | 61.593 | 54.866 | 44.958 | 40.177 | 45.873 | 66.678 | 57.343 | 56.188 | 54.300 | 64.079 | 47.047 | 36.783 | 57.605 | 45.127 | 37.823 | 57.667 | 43.387 | 63.945 | 64.433 | 58.485 | 38.083 | 48.395 | 45.630 | 44.943 | 66.760 | 36.342 | 75.662 | 37.239 | 44.081 | 44.943 | 59.008 | 40.474 | 52.392 | 45.254 | 53.154 | 43.940 | 64.268 | 34.532 | 45.165 | 40.419 | 39.171 | 32.023 | 38.154 | 46.692 | 36.935 | 0.042 | 0.085 | 0.013 | 0.066 | 0.039 | 0.033 | 0.135 | 0.102 | 0.280 | 0.720 | 0.047 | 0.048 | 0.011 | 0.012 | 0.022 | 0.011 | 0.023 | 0.035 | 0.006 | 0.009 | 0.042 | 0.028 | 0.019 | 0.017 | 0.003 | 0.023 | 0.059 | 0.035 | 0.108 | 0.892 | 0.014 | 0.025 | 0.000 | 0.004 | 0.010 | 0.000 | 0.009 | 0.008 | 0.000 | 0.000 | 0.026 | 0.000 | 0.011 | 0.013 | 0 | 0.753 | 0.598 | 0.829 | 0.710 | 0.246 | 0.890 | 0.520 | 0.152 | 0.104 | 0.066 | 0.008 | 0.022 | 0.005 | 0.004 | 0.047 | 0.076 | 0.145 | 0.064 | 0.046 | 0.065 | 0.008 | 0.230 | 0.153 | 0.040 | 0.016 | 0.014 | 0.013 | 0.010 | 0.054 | 0.039 | 0.015 | 0.006 | 0.003 | 0.003 | 0.089 | 0.001 | 0.003 | 0.006 | 0.003 | 0.088 | 0.025 | 0.014 | 0.009 | 0.019 | 0.010 | 0.018 | 0.042 | 0.015 | 0.020 | 0.006 | 0.020 | 0.008 | 0.006 | 0.000 | 0.004 | 0.075 | 0.022 | 0.022 | 0.026 | 0.012 | 0.003 | 0.140 | 0.042 | 0.085 | 0.013 | 0.173 | 0.021 | 0.087 | 0.068 | 0.069 | 0.031 | 0.025 | 0.004 | 0.005 | 0.002 | 0.003 | 0.010 | 0.002 | 0.005 | 0.001 | 0.001 | 0.001 | 0.136 | 0.033 | 0.040 | 0.001 | 0.000 | 0.002 | 0.000 | 0.018 | 0.008 | 0.024 | 0.001 | 0.008 | 52.065 | 47.935 | 58.657 | 40.456 | 45.895 | 55.262 | 53.026 | 44.037 | 0.232 | 0.279 | 0.268 | 0.222 |
| 12.072 | 125 | 0.221 | 0.034 | 0 | 0 | 0.000 | 0 | 58.409 | 51.115 | 63.655 | 51.542 | 52.596 | 52.497 | 57.839 | 56.465 | 47.289 | 51.411 | 58.862 | 57.768 | 51.601 | 50.602 | 60.010 | 62.166 | 48.519 | 56.739 | 58.906 | 64.698 | 39.727 | 61.179 | 61.789 | 58.539 | 53.385 | 59.776 | 43.797 | 55.961 | 52.055 | 38.610 | 50.719 | 55.634 | 54.418 | 34.803 | 62.363 | 56.194 | 38.739 | 55.696 | 55.097 | 62.863 | 53.799 | 56.599 | 38.739 | 62.322 | 60.753 | 53.448 | 53.238 | 48.850 | 49.997 | 44.902 | 50.653 | 49.244 | 69.531 | 43.381 | 41.069 | 45.942 | 57.196 | 40.690 | 0.038 | 0.129 | 0.019 | 0.045 | 0.068 | 0.056 | 0.130 | 0.073 | 0.228 | 0.772 | 0.031 | 0.063 | 0.001 | 0.004 | 0.012 | 0.016 | 0.031 | 0.017 | 0.002 | 0.009 | 0.023 | 0.020 | 0.008 | 0.011 | 0.001 | 0.025 | 0.041 | 0.016 | 0.059 | 0.941 | 0.004 | 0.024 | 0.000 | 0.014 | 0.001 | 0.006 | 0.004 | 0.007 | 0.001 | 0.001 | 0.000 | 0.003 | 0.000 | 0.000 | 0 | 0.418 | 0.789 | 0.630 | 0.729 | 0.221 | 0.915 | 0.564 | 0.195 | 0.113 | 0.045 | 0.002 | 0.057 | 0.004 | 0.005 | 0.082 | 0.060 | 0.133 | 0.100 | 0.058 | 0.059 | 0.019 | 0.299 | 0.186 | 0.047 | 0.020 | 0.028 | 0.018 | 0.025 | 0.054 | 0.039 | 0.014 | 0.003 | 0.002 | 0.004 | 0.113 | 0.004 | 0.001 | 0.001 | 0.006 | 0.125 | 0.034 | 0.016 | 0.014 | 0.023 | 0.023 | 0.026 | 0.017 | 0.005 | 0.005 | 0.007 | 0.009 | 0.003 | 0.003 | 0.000 | 0.001 | 0.072 | 0.012 | 0.025 | 0.023 | 0.017 | 0.005 | 0.187 | 0.038 | 0.129 | 0.019 | 0.143 | 0.018 | 0.072 | 0.058 | 0.059 | 0.046 | 0.007 | 0.001 | 0.009 | 0.000 | 0.000 | 0.006 | 0.002 | 0.000 | 0.001 | 0.002 | 0.000 | 0.184 | 0.076 | 0.052 | 0.007 | 0.000 | 0.006 | 0.001 | 0.003 | 0.004 | 0.033 | 0.002 | 0.001 | 62.761 | 37.239 | 62.708 | 52.666 | 57.492 | 62.734 | 48.323 | 44.286 | 0.270 | 0.295 | 0.227 | 0.208 |
| 32.390 | 59 | 0.312 | 0.012 | 0 | 0 | 0.000 | 0 | 59.149 | 29.627 | 71.979 | 45.060 | 65.171 | 61.465 | 47.947 | 68.660 | 57.135 | 53.055 | 53.713 | 42.775 | 72.075 | 56.649 | 42.993 | 36.713 | 52.205 | 38.087 | 61.052 | 33.360 | 49.481 | 57.400 | 61.881 | 49.823 | 50.881 | 57.820 | 45.523 | 46.527 | 43.515 | 46.242 | 26.834 | 32.728 | 55.522 | 50.803 | 48.968 | 67.605 | 51.356 | 36.110 | 48.683 | 36.827 | 41.080 | 64.000 | 51.356 | 49.287 | 46.700 | 64.254 | 53.011 | 73.809 | 40.819 | 66.948 | 49.473 | 36.675 | 52.648 | 51.428 | 51.055 | 40.996 | 64.101 | 42.843 | 0.015 | 0.102 | 0.006 | 0.008 | 0.058 | 0.007 | 0.110 | 0.102 | 0.216 | 0.784 | 0.010 | 0.041 | 0.000 | 0.008 | 0.016 | 0.016 | 0.038 | 0.031 | 0.005 | 0.024 | 0.033 | 0.028 | 0.004 | 0.003 | 0.001 | 0.002 | 0.022 | 0.020 | 0.041 | 0.959 | 0.000 | 0.016 | 0.000 | 0.001 | 0.001 | 0.005 | 0.000 | 0.000 | 0.000 | 0.003 | 0.003 | 0.004 | 0.000 | 0.000 | 0 | 0.799 | 0.902 | 0.226 | 0.460 | 0.312 | 0.884 | 0.514 | 0.130 | 0.066 | 0.008 | 0.018 | 0.026 | 0.006 | 0.008 | 0.064 | 0.064 | 0.159 | 0.065 | 0.041 | 0.068 | 0.010 | 0.218 | 0.123 | 0.049 | 0.027 | 0.016 | 0.010 | 0.029 | 0.047 | 0.029 | 0.018 | 0.004 | 0.004 | 0.004 | 0.139 | 0.003 | 0.002 | 0.029 | 0.013 | 0.122 | 0.040 | 0.009 | 0.011 | 0.025 | 0.016 | 0.035 | 0.018 | 0.005 | 0.006 | 0.003 | 0.017 | 0.003 | 0.009 | 0.003 | 0.001 | 0.101 | 0.031 | 0.015 | 0.044 | 0.010 | 0.005 | 0.123 | 0.015 | 0.102 | 0.006 | 0.099 | 0.011 | 0.061 | 0.028 | 0.075 | 0.066 | 0.003 | 0.001 | 0.006 | 0.001 | 0.002 | 0.001 | 0.000 | 0.000 | 0.000 | 0.000 | 0.001 | 0.166 | 0.030 | 0.072 | 0.009 | 0.005 | 0.001 | 0.000 | 0.015 | 0.019 | 0.012 | 0.002 | 0.001 | 47.897 | 52.103 | 68.591 | 45.066 | 46.460 | 57.317 | 59.782 | 48.457 | 0.219 | 0.270 | 0.282 | 0.229 |
| 24.327 | 101 | 0.326 | 0.024 | 0 | 0 | 0.000 | 0 | 71.968 | 50.677 | 66.095 | 71.805 | 65.531 | 64.312 | 55.217 | 68.608 | 73.095 | 48.610 | 47.741 | 76.015 | 64.931 | 43.375 | 72.554 | 69.183 | 47.031 | 54.417 | 70.859 | 51.675 | 67.484 | 32.746 | 50.272 | 42.742 | 29.499 | 34.411 | 33.995 | 29.642 | 62.054 | 54.525 | 37.826 | 52.394 | 70.989 | 38.718 | 67.106 | 45.697 | 45.252 | 44.242 | 37.979 | 56.231 | 45.742 | 52.428 | 45.252 | 67.293 | 58.329 | 41.322 | 46.470 | 63.494 | 55.802 | 70.738 | 43.410 | 53.916 | 41.123 | 45.683 | 43.173 | 43.746 | 52.472 | 35.439 | 0.023 | 0.079 | 0.021 | 0.024 | 0.041 | 0.130 | 0.176 | 0.046 | 0.246 | 0.754 | 0.026 | 0.068 | 0.000 | 0.022 | 0.025 | 0.033 | 0.037 | 0.013 | 0.000 | 0.006 | 0.020 | 0.012 | 0.011 | 0.010 | 0.000 | 0.050 | 0.061 | 0.011 | 0.080 | 0.920 | 0.008 | 0.025 | 0.000 | 0.012 | 0.003 | 0.007 | 0.011 | 0.000 | 0.000 | 0.000 | 0.003 | 0.006 | 0.008 | 0.006 | 0 | 0.865 | 0.725 | 0.527 | 0.937 | 0.326 | 0.867 | 0.516 | 0.106 | 0.065 | 0.024 | 0.009 | 0.027 | 0.002 | 0.003 | 0.042 | 0.085 | 0.154 | 0.071 | 0.036 | 0.068 | 0.013 | 0.195 | 0.109 | 0.047 | 0.022 | 0.012 | 0.015 | 0.014 | 0.057 | 0.050 | 0.006 | 0.002 | 0.002 | 0.001 | 0.089 | 0.004 | 0.002 | 0.000 | 0.003 | 0.108 | 0.030 | 0.018 | 0.013 | 0.018 | 0.011 | 0.028 | 0.013 | 0.004 | 0.004 | 0.003 | 0.011 | 0.003 | 0.004 | 0.002 | 0.002 | 0.090 | 0.022 | 0.028 | 0.035 | 0.021 | 0.003 | 0.122 | 0.023 | 0.079 | 0.021 | 0.148 | 0.015 | 0.079 | 0.056 | 0.073 | 0.058 | 0.007 | 0.003 | 0.009 | 0.001 | 0.000 | 0.002 | 0.000 | 0.001 | 0.001 | 0.000 | 0.000 | 0.140 | 0.043 | 0.066 | 0.004 | 0.002 | 0.001 | 0.000 | 0.011 | 0.003 | 0.006 | 0.001 | 0.002 | 70.956 | 29.044 | 61.241 | 55.539 | 62.776 | 65.920 | 42.175 | 40.163 | 0.297 | 0.312 | 0.200 | 0.190 |

### Full: Analyze Style

To get at stylistic uniqueness, we can calculate Language Style Matching
between each speech and the mean of all speeches:

``` r
# Currently, the lingmatch package only automatically handles
# `liwc.` prefixes, so we'll rename the `liwc15.` ones.
colnames(processed) <- sub("liwc15", "liwc", colnames(processed), fixed = TRUE)

processed$lsm_mean <- lingmatch(processed, mean, type = "lsm")$sim

kable(processed[
  order(processed$lsm_mean)[1:10],
  c("name", "school", "year", "lsm_mean", "summary.word_count")
], digits = 3, row.names = FALSE)
```

| name | school | year | lsm_mean | summary.word_count |
|:---|:---|---:|---:|---:|
| Gary Malkowski | Gallaudet University | 2011 | 0.751 | 2154 |
| Theodor ‘Dr. Seuss’ Geisel | Lake Forest College | 1977 | 0.764 | 96 |
| Makoto Fujimura | Belhaven University | 2011 | 0.820 | 2569 |
| Dwight Eisenhower | Penn State | 1955 | 0.831 | 2518 |
| George C. Marshall | Harvard University | 1947 | 0.833 | 1449 |
| Lewis Lapham | St. John’s College | 2003 | 0.835 | 3688 |
| Rev. Joseph L. Levesque | Niagara University | 2007 | 0.846 | 483 |
| Edward W. Brooke | Wellesley College | 1969 | 0.847 | 3083 |
| Janet Napolitano | Northeastern University | 2014 | 0.853 | 1526 |
| Whoopi Goldberg | Savannah College of Art and Design | 2011 | 0.855 | 1248 |

Here, it is notable that the most stylistically unique speech was
delivered in American Sign Language, and the second most stylistically
unique speech was a short rhyme.

We might also want to see which speeches are most similar to one
another:

``` r
# calculate all pairwise comparisons
lsm_pairs <- lingmatch(processed, type = "lsm", symmetrical = TRUE)$sim

# set self-matches to 0
diag(lsm_pairs) <- 0

# identify the closest match to each speech
speeches$match <- max.col(lsm_pairs, "last")
best_match <- lsm_pairs[
  speeches$match + (seq_len(nrow(lsm_pairs)) - 1) * nrow(lsm_pairs)
]

# look at the top matches
top_matches <- order(-best_match)[1:20]
top_matches <- data.frame(a = top_matches, b = speeches$match[top_matches])
top_matches <- top_matches[!duplicated(apply(
  top_matches, 1, function(pair) paste(sort(pair), collapse = "")
)), ]
kable(data.frame(
  speeches[top_matches$a, 2:4],
  Similarity = best_match[top_matches$a],
  speeches[top_matches$b, 2:4],
  check.names = FALSE
), digits = 3, row.names = FALSE)
```

| name | school | year | Similarity | name | school | year |
|:---|:---|---:|---:|:---|:---|---:|
| Cynthia Enloe | Connecticut College | 2011 | 0.999 | Howard Gordon | Connecticut College | 2013 |
| Benjamin Carson Jr. | Niagara University | 2003 | 0.984 | Jonathon Youshaei | Deerfield High School | 2009 |
| John Legend | University of Pennsylvania | 2014 | 0.981 | Sheryl Sandberg | City Colleges of Chicago | 2014 |
| Arianna Huffington | Sarah Lawrence College | 2011 | 0.980 | Ronald Reagan | Eureka College | 1957 |
| Amy Poehler | Harvard University | 2011 | 0.978 | Sheryl Sandberg | City Colleges of Chicago | 2014 |
| Drew Houston | Massachusetts Institute of Technology | 2013 | 0.976 | Melissa Harris-Perry | Wellesley College | 2012 |
| Alan Alda | Connecticut College | 1980 | 0.975 | Nora Ephron | Wellesley College | 1996 |
| Arianna Huffington | Vassar College | 2015 | 0.975 | Tim Cook | Auburn University | 2010 |
| James Carville | Hobart and William Smith Colleges | 2013 | 0.975 | Woody Hayes | Ohio State University | 1986 |
| Mindy Kaling | Harvard Law School | 2014 | 0.975 | Stephen Colbert | Wake Forest University | 2015 |
| Barbara Bush | Wellesley College | 1990 | 0.975 | Daniel S. Goldin | Massachusetts Institute of Technology | 2001 |

### Full: Analyze Content

To look at content over time, we might focus on a potentially
interesting framework, such as drives:

``` r
library(splot)

# select drives categories
drives <- processed[, grep("drives", colnames(processed), value = TRUE, fixed = TRUE)]

# identify those more correlated with time (excluding the few earliest cases)
later_times <- processed$year > 1980
drives <- drives[, order(-abs(cor(
  drives[later_times, ], processed$year[later_times]
)))[1:3]]

splot(
  drives ~ year, processed, year > 1980,
  title = FALSE, laby = "Score", lpos = "top"
)
```

![drives categories over
time](commencement_example_files/figure-html/unnamed-chunk-10-1.svg)

To better visualize the effects, we might look between aggregated blocks
of time:

``` r
time_median <- median(processed$year)
processed$time_period <- paste(c("<", ">="), time_median)[
  (processed$year >= time_median) + 1
]

splot(
  scale(drives) ~ time_period, processed,
  title = FALSE, laby = "Score (Scaled)", lpos = "top"
)
```

![drives categories between time
periods](commencement_example_files/figure-html/unnamed-chunk-11-1.svg)

This suggests that references to risk and reward have increased since
the 2000s while references to power have decreased at a similar rate.
(Note that error bars represent how much variance there is within
groups, which allows you to eyeball the statistical significance of mean
differences.)

The shift in emphasis from power to risk-reward could reflect that
commencement speakers are now focusing more abstractly on the potential
benefits and hazards of life after graduation, whereas earlier speakers
more narrowly focused on ambition and dominance (perhaps referring to
power held by past alumni and projecting the potential for graduates to
climb social ladders in the future). You could examine a sample of
speeches that show this pattern most dramatically (speeches high in
risk-reward and low in power in recent years, and vice versa for
pre-2009 speeches) to help determine how these themes have shifted and
what specific motives or framing devices seem to have been
(de)emphasized.

## Analyze Segments

Another thing we might look for is trends within each speech. For
instance, are there common emotional trajectories over the course of a
speech?

One way to look at this would be to split texts into roughly equal
sizes, and score each section:

``` r
# split texts into 3 segments each, keeping sentences together
segmented_text <- read.segments(
  text = speeches$text, segment = 3, bysentence = TRUE
)
segmented_text <- cbind(speeches[segmented_text$input, 1:4], segmented_text)

kable(segmented_text[1:9, 2:7], row.names = FALSE)
```

| name             | school                 | year | input | segment |   WC |
|:-----------------|:-----------------------|-----:|------:|--------:|-----:|
| Aaron Sorkin     | Syracuse University    | 2012 |     1 |       1 |  853 |
| Aaron Sorkin     | Syracuse University    | 2012 |     1 |       2 |  842 |
| Aaron Sorkin     | Syracuse University    | 2012 |     1 |       3 |  830 |
| Abigail Washburn | Colorado College       | 2012 |     2 |       1 | 1008 |
| Abigail Washburn | Colorado College       | 2012 |     2 |       2 | 1024 |
| Abigail Washburn | Colorado College       | 2012 |     2 |       3 |  969 |
| Adam Savage      | Sarah Lawrence College | 2012 |     3 |       1 |  489 |
| Adam Savage      | Sarah Lawrence College | 2012 |     3 |       2 |  488 |
| Adam Savage      | Sarah Lawrence College | 2012 |     3 |       3 |  477 |

### Segments: Process Text

Now we can send each segment to the API to be scored:

``` r
processed_segments <- receptiviti(
  segmented_text$text,
  version = "v2", context = "spoken"
)
segmented_text <- cbind(segmented_text, processed_segments)

kable(segmented_text[1:9, -(1:10)], digits = 3, row.names = FALSE)
```

| summary.word_count | summary.words_per_sentence | summary.sentence_count | summary.six_plus_words | summary.capitals | summary.emojis | summary.emoticons | summary.hashtags | summary.urls | big_5.extraversion | big_5.active | big_5.assertive | big_5.cheerful | big_5.energetic | big_5.friendly | big_5.sociable | big_5.openness | big_5.adventurous | big_5.artistic | big_5.emotionally_aware | big_5.imaginative | big_5.intellectual | big_5.liberal | big_5.conscientiousness | big_5.ambitious | big_5.cautious | big_5.disciplined | big_5.dutiful | big_5.organized | big_5.self_assured | big_5.neuroticism | big_5.aggressive | big_5.anxiety_prone | big_5.impulsive | big_5.melancholy | big_5.self_conscious | big_5.stress_prone | big_5.agreeableness | big_5.cooperative | big_5.empathetic | big_5.genuine | big_5.generous | big_5.humble | big_5.trusting | social_dynamics.social | social_dynamics.affiliation | social_dynamics.inward_focus | social_dynamics.outward_focus | social_dynamics.authentic | social_dynamics.negations | social_dynamics.clout | drives.affiliation | drives.achievement | drives.risk_seeking | drives.risk_aversion | drives.risk_focus | drives.power | drives.reward | cognition.analytical_thinking | cognition.cognitive_processes | cognition.causation | cognition.certainty | cognition.comparisons | cognition.differentiation | cognition.discrepancies | cognition.insight | cognition.tentative | temporal_and_orientation.focus_past | temporal_and_orientation.focus_present | temporal_and_orientation.focus_future | temporal_and_orientation.self_focus | temporal_and_orientation.external_focus | sallee.sentiment | sallee.goodfeel | sallee.badfeel | sallee.emotionality | sallee.non_emotion | sallee.ambifeel | sallee.admiration | sallee.amusement | sallee.excitement | sallee.gratitude | sallee.joy | sallee.love | sallee.anger | sallee.boredom | sallee.disgust | sallee.fear | sallee.sadness | sallee.calmness | sallee.curiosity | sallee.surprise | sparse_sallee.sentiment | sparse_sallee.goodfeel | sparse_sallee.badfeel | sparse_sallee.emotionality | sparse_sallee.non_emotion | sparse_sallee.ambifeel | sparse_sallee.admiration | sparse_sallee.amusement | sparse_sallee.excitement | sparse_sallee.gratitude | sparse_sallee.joy | sparse_sallee.love | sparse_sallee.anger | sparse_sallee.boredom | sparse_sallee.disgust | sparse_sallee.fear | sparse_sallee.sadness | sparse_sallee.calmness | sparse_sallee.curiosity | sparse_sallee.surprise | liwc15.analytical_thinking | liwc15.clout | liwc15.authentic | liwc15.emotional_tone | liwc15.six_plus_words | liwc15.dictionary_words | liwc15.function_words | liwc15.pronouns | liwc15.personal_pronouns | liwc15.i | liwc15.we | liwc15.you | liwc15.she_he | liwc15.they | liwc15.impersonal_pronouns | liwc15.articles | liwc15.prepositions | liwc15.auxiliary_verbs | liwc15.adverbs | liwc15.conjunctions | liwc15.negations | liwc15.other_grammar | liwc15.verbs | liwc15.adjectives | liwc15.comparisons | liwc15.interrogatives | liwc15.numbers | liwc15.quantifiers | liwc15.affective_processes | liwc15.positive_emotion_words | liwc15.negative_emotion_words | liwc15.anxiety_words | liwc15.anger_words | liwc15.sad_words | liwc15.social_processes | liwc15.family | liwc15.friends | liwc15.female | liwc15.male | liwc15.cognitive_processes | liwc15.insight | liwc15.causation | liwc15.discrepancies | liwc15.tentative | liwc15.certainty | liwc15.differentiation | liwc15.perceptual_processes | liwc15.see | liwc15.hear | liwc15.feel | liwc15.biological_processes | liwc15.body | liwc15.health | liwc15.sexual | liwc15.ingestion | liwc15.drives | liwc15.affiliation | liwc15.achievement | liwc15.power | liwc15.reward | liwc15.risk | liwc15.time_orientation | liwc15.focus_past | liwc15.focus_present | liwc15.focus_future | liwc15.relativity | liwc15.motion | liwc15.space | liwc15.time | liwc15.personal_concerns | liwc15.work | liwc15.leisure | liwc15.home | liwc15.money | liwc15.religion | liwc15.death | liwc15.informal_language | liwc15.swear_words | liwc15.netspeak | liwc15.assent | liwc15.nonfluencies | liwc15.filler_words | liwc15.all_punctuation | liwc15.periods | liwc15.commas | liwc15.colons | liwc15.semicolons | liwc15.question_marks | liwc15.exclamations | liwc15.dashes | liwc15.quotes | liwc15.apostrophes | liwc15.parentheses | liwc15.other_punctuation | disc_dimensions.bold_assertive_outgoing | disc_dimensions.calm_methodical_reserved | disc_dimensions.people_relationship_emotion_focus | disc_dimensions.task_system_object_focus | disc_dimensions.d_axis | disc_dimensions.i_axis | disc_dimensions.s_axis | disc_dimensions.c_axis | disc_dimensions.d_axis_proportional | disc_dimensions.i_axis_proportional | disc_dimensions.s_axis_proportional | disc_dimensions.c_axis_proportional |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 890 | 20.698 | 43 | 0.182 | 0.026 | 0 | 0 | 0.000 | 0 | 66.450 | 62.411 | 55.284 | 48.455 | 81.421 | 66.757 | 63.074 | 41.371 | 40.570 | 54.250 | 65.634 | 54.417 | 25.722 | 57.026 | 69.416 | 62.244 | 57.394 | 49.055 | 82.194 | 45.669 | 55.019 | 47.886 | 63.021 | 44.525 | 54.177 | 36.178 | 41.548 | 56.744 | 73.118 | 47.333 | 52.590 | 78.366 | 73.302 | 61.003 | 66.740 | 70.850 | 49.212 | 55.632 | 65.193 | 63.932 | 36.991 | 63.737 | 49.212 | 54.764 | 50.819 | 38.352 | 43.132 | 39.839 | 53.508 | 43.867 | 35.257 | 51.084 | 42.596 | 53.626 | 30.739 | 39.515 | 44.103 | 34.763 | 0.045 | 0.113 | 0.025 | 0.045 | 0.084 | 0.059 | 0.138 | 0.079 | 0.236 | 0.764 | 0.019 | 0.063 | 0.000 | 0.012 | 0.031 | 0.005 | 0.044 | 0.058 | 0.035 | 0.032 | 0.019 | 0.011 | 0.000 | 0.000 | 0.000 | -0.018 | 0.036 | 0.055 | 0.091 | 0.909 | 0.000 | 0.006 | 0.000 | 0.000 | 0.011 | 0.000 | 0.019 | 0.037 | 0.037 | 0.037 | 0.018 | 0.000 | 0.000 | 0.000 | 0 | 0.400 | 0.898 | 0.647 | 0.554 | 0.182 | 0.931 | 0.551 | 0.178 | 0.129 | 0.045 | 0.010 | 0.051 | 0.006 | 0.018 | 0.048 | 0.065 | 0.115 | 0.110 | 0.058 | 0.071 | 0.008 | 0.292 | 0.190 | 0.037 | 0.029 | 0.025 | 0.018 | 0.025 | 0.052 | 0.034 | 0.018 | 0.002 | 0.013 | 0.001 | 0.146 | 0.015 | 0.002 | 0.008 | 0.012 | 0.090 | 0.022 | 0.017 | 0.010 | 0.017 | 0.011 | 0.017 | 0.022 | 0.009 | 0.011 | 0.002 | 0.025 | 0.002 | 0.011 | 0.003 | 0.003 | 0.071 | 0.028 | 0.019 | 0.015 | 0.019 | 0.002 | 0.183 | 0.045 | 0.113 | 0.025 | 0.164 | 0.024 | 0.057 | 0.083 | 0.054 | 0.038 | 0.011 | 0.004 | 0.001 | 0.001 | 0.000 | 0.015 | 0.010 | 0.001 | 0.000 | 0.003 | 0.000 | 0.179 | 0.047 | 0.069 | 0.002 | 0.004 | 0.001 | 0.000 | 0.011 | 0.011 | 0.033 | 0.000 | 0.000 | 63.823 | 36.177 | 77.271 | 40.031 | 50.546 | 70.226 | 52.872 | 38.055 | 0.239 | 0.332 | 0.250 | 0.180 |
| 865 | 18.404 | 47 | 0.220 | 0.034 | 0 | 0 | 0.000 | 0 | 42.485 | 53.836 | 50.662 | 32.728 | 60.076 | 30.113 | 45.397 | 36.582 | 39.827 | 36.085 | 45.631 | 55.732 | 46.932 | 29.262 | 38.998 | 36.534 | 65.905 | 45.705 | 40.750 | 51.702 | 40.497 | 57.029 | 61.861 | 55.203 | 26.244 | 62.129 | 46.400 | 46.889 | 31.566 | 42.753 | 34.213 | 72.768 | 26.761 | 26.377 | 38.335 | 44.810 | 45.243 | 65.583 | 46.319 | 68.682 | 51.889 | 39.503 | 45.243 | 53.921 | 60.839 | 67.243 | 77.774 | 53.465 | 44.663 | 58.611 | 43.591 | 47.547 | 35.515 | 40.593 | 47.237 | 45.868 | 58.219 | 38.892 | 0.092 | 0.051 | 0.015 | 0.064 | 0.054 | -0.048 | 0.060 | 0.108 | 0.190 | 0.810 | 0.021 | 0.014 | 0.016 | 0.017 | 0.007 | 0.017 | 0.004 | 0.053 | 0.004 | 0.009 | 0.041 | 0.041 | 0.007 | 0.005 | 0.000 | -0.027 | 0.000 | 0.027 | 0.029 | 0.971 | 0.002 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.013 | 0.000 | 0.000 | 0.000 | 0 | 0.655 | 0.528 | 0.721 | 0.471 | 0.220 | 0.911 | 0.533 | 0.163 | 0.118 | 0.064 | 0.014 | 0.018 | 0.018 | 0.003 | 0.045 | 0.087 | 0.125 | 0.084 | 0.027 | 0.074 | 0.017 | 0.262 | 0.183 | 0.030 | 0.017 | 0.015 | 0.025 | 0.018 | 0.046 | 0.029 | 0.017 | 0.005 | 0.001 | 0.005 | 0.087 | 0.001 | 0.001 | 0.010 | 0.010 | 0.109 | 0.035 | 0.015 | 0.014 | 0.021 | 0.008 | 0.031 | 0.009 | 0.002 | 0.003 | 0.002 | 0.016 | 0.001 | 0.013 | 0.000 | 0.002 | 0.083 | 0.022 | 0.018 | 0.027 | 0.013 | 0.013 | 0.158 | 0.092 | 0.051 | 0.015 | 0.148 | 0.023 | 0.065 | 0.064 | 0.099 | 0.054 | 0.031 | 0.002 | 0.005 | 0.001 | 0.006 | 0.002 | 0.000 | 0.000 | 0.000 | 0.002 | 0.000 | 0.164 | 0.053 | 0.061 | 0.002 | 0.001 | 0.001 | 0.000 | 0.008 | 0.012 | 0.023 | 0.000 | 0.002 | 46.899 | 53.101 | 46.507 | 48.643 | 47.763 | 46.703 | 49.695 | 50.823 | 0.245 | 0.240 | 0.255 | 0.261 |
| 861 | 19.568 | 44 | 0.175 | 0.030 | 0 | 0 | 0.000 | 0 | 70.568 | 59.646 | 59.470 | 62.395 | 64.962 | 62.851 | 77.836 | 58.559 | 60.519 | 63.493 | 70.082 | 77.188 | 31.287 | 52.408 | 69.509 | 67.047 | 45.136 | 53.267 | 67.189 | 71.737 | 52.856 | 58.775 | 63.372 | 44.478 | 49.280 | 63.687 | 36.883 | 46.705 | 65.898 | 41.511 | 64.661 | 61.507 | 67.566 | 60.181 | 55.095 | 66.385 | 43.052 | 45.901 | 61.124 | 44.396 | 48.364 | 64.092 | 43.052 | 41.079 | 56.821 | 44.294 | 47.226 | 47.002 | 52.790 | 48.191 | 37.116 | 49.933 | 56.529 | 50.881 | 36.729 | 53.826 | 35.579 | 31.719 | 0.044 | 0.111 | 0.022 | 0.027 | 0.078 | 0.069 | 0.137 | 0.068 | 0.249 | 0.751 | 0.045 | 0.028 | 0.010 | 0.012 | 0.015 | 0.030 | 0.053 | 0.022 | 0.002 | 0.012 | 0.012 | 0.021 | 0.013 | 0.011 | 0.000 | 0.009 | 0.029 | 0.020 | 0.056 | 0.944 | 0.007 | 0.009 | 0.007 | 0.008 | 0.002 | 0.009 | 0.000 | 0.008 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.007 | 0 | 0.475 | 0.903 | 0.343 | 0.735 | 0.175 | 0.929 | 0.548 | 0.177 | 0.105 | 0.027 | 0.006 | 0.053 | 0.007 | 0.012 | 0.072 | 0.067 | 0.130 | 0.095 | 0.058 | 0.071 | 0.015 | 0.287 | 0.182 | 0.043 | 0.027 | 0.024 | 0.028 | 0.019 | 0.046 | 0.036 | 0.010 | 0.001 | 0.002 | 0.003 | 0.136 | 0.003 | 0.013 | 0.000 | 0.010 | 0.094 | 0.015 | 0.016 | 0.019 | 0.014 | 0.017 | 0.022 | 0.033 | 0.014 | 0.007 | 0.009 | 0.016 | 0.000 | 0.014 | 0.002 | 0.001 | 0.064 | 0.019 | 0.009 | 0.021 | 0.019 | 0.003 | 0.178 | 0.044 | 0.111 | 0.022 | 0.148 | 0.023 | 0.067 | 0.063 | 0.056 | 0.023 | 0.012 | 0.009 | 0.006 | 0.005 | 0.002 | 0.001 | 0.001 | 0.000 | 0.000 | 0.000 | 0.000 | 0.175 | 0.050 | 0.059 | 0.002 | 0.000 | 0.001 | 0.000 | 0.005 | 0.014 | 0.039 | 0.000 | 0.005 | 54.296 | 45.704 | 72.998 | 53.560 | 53.927 | 62.956 | 57.761 | 49.476 | 0.241 | 0.281 | 0.258 | 0.221 |
| 1045 | 34.833 | 30 | 0.273 | 0.025 | 0 | 0 | 0.000 | 0 | 57.940 | 55.324 | 57.148 | 57.004 | 48.395 | 55.226 | 57.357 | 70.500 | 35.766 | 69.581 | 66.990 | 81.852 | 49.798 | 62.037 | 64.288 | 60.540 | 45.551 | 53.824 | 63.795 | 58.548 | 58.949 | 48.198 | 53.916 | 49.256 | 38.247 | 52.871 | 44.489 | 36.704 | 59.201 | 51.604 | 62.585 | 59.747 | 58.337 | 36.449 | 56.015 | 48.753 | 44.032 | 64.334 | 40.418 | 72.852 | 42.680 | 46.274 | 44.032 | 66.830 | 45.293 | 48.491 | 45.196 | 59.139 | 46.931 | 61.933 | 35.286 | 48.094 | 43.153 | 41.516 | 26.767 | 43.448 | 44.675 | 38.147 | 0.043 | 0.081 | 0.018 | 0.061 | 0.045 | 0.111 | 0.180 | 0.069 | 0.279 | 0.721 | 0.034 | 0.088 | 0.005 | 0.013 | 0.017 | 0.017 | 0.030 | 0.020 | 0.004 | 0.010 | 0.029 | 0.038 | 0.026 | 0.008 | 0.000 | 0.087 | 0.093 | 0.006 | 0.110 | 0.890 | 0.010 | 0.057 | 0.000 | 0.006 | 0.000 | 0.000 | 0.015 | 0.000 | 0.000 | 0.000 | 0.006 | 0.000 | 0.017 | 0.009 | 0 | 0.712 | 0.631 | 0.785 | 0.847 | 0.273 | 0.892 | 0.513 | 0.155 | 0.106 | 0.061 | 0.006 | 0.018 | 0.013 | 0.008 | 0.049 | 0.071 | 0.138 | 0.068 | 0.044 | 0.061 | 0.011 | 0.220 | 0.144 | 0.035 | 0.018 | 0.020 | 0.011 | 0.011 | 0.056 | 0.045 | 0.011 | 0.005 | 0.001 | 0.003 | 0.096 | 0.000 | 0.001 | 0.013 | 0.001 | 0.090 | 0.023 | 0.015 | 0.012 | 0.020 | 0.011 | 0.013 | 0.045 | 0.020 | 0.017 | 0.006 | 0.015 | 0.004 | 0.009 | 0.000 | 0.001 | 0.080 | 0.020 | 0.028 | 0.032 | 0.014 | 0.003 | 0.143 | 0.043 | 0.081 | 0.018 | 0.186 | 0.021 | 0.086 | 0.081 | 0.075 | 0.033 | 0.019 | 0.007 | 0.009 | 0.002 | 0.007 | 0.013 | 0.000 | 0.006 | 0.002 | 0.003 | 0.000 | 0.132 | 0.026 | 0.042 | 0.002 | 0.000 | 0.004 | 0.000 | 0.018 | 0.008 | 0.023 | 0.000 | 0.010 | 57.084 | 42.916 | 66.913 | 46.522 | 51.533 | 61.803 | 53.588 | 44.683 | 0.244 | 0.292 | 0.253 | 0.211 |
| 1050 | 27.632 | 38 | 0.230 | 0.044 | 0 | 0 | 0.003 | 0 | 58.443 | 81.444 | 47.045 | 48.083 | 67.941 | 50.379 | 56.533 | 57.115 | 44.233 | 65.836 | 53.485 | 73.225 | 44.172 | 49.734 | 49.915 | 40.276 | 31.710 | 38.771 | 63.297 | 51.260 | 62.454 | 48.062 | 64.197 | 37.292 | 42.034 | 48.722 | 40.572 | 34.185 | 61.033 | 41.134 | 77.726 | 68.609 | 59.762 | 37.709 | 44.127 | 44.375 | 43.970 | 79.430 | 21.669 | 80.706 | 35.107 | 33.720 | 43.970 | 49.375 | 39.988 | 44.578 | 41.999 | 48.138 | 46.837 | 71.329 | 25.376 | 35.032 | 36.594 | 38.284 | 28.882 | 35.302 | 40.144 | 29.100 | 0.051 | 0.071 | 0.010 | 0.090 | 0.015 | 0.024 | 0.126 | 0.102 | 0.277 | 0.723 | 0.051 | 0.024 | 0.028 | 0.016 | 0.024 | 0.015 | 0.021 | 0.041 | 0.001 | 0.000 | 0.045 | 0.006 | 0.010 | 0.010 | 0.004 | -0.007 | 0.051 | 0.058 | 0.114 | 0.886 | 0.005 | 0.012 | 0.000 | 0.006 | 0.014 | 0.000 | 0.012 | 0.018 | 0.001 | 0.000 | 0.040 | 0.000 | 0.008 | 0.005 | 0 | 0.875 | 0.439 | 0.907 | 0.655 | 0.230 | 0.879 | 0.507 | 0.138 | 0.105 | 0.090 | 0.003 | 0.010 | 0.001 | 0.002 | 0.033 | 0.082 | 0.163 | 0.045 | 0.044 | 0.060 | 0.007 | 0.224 | 0.149 | 0.040 | 0.015 | 0.007 | 0.017 | 0.010 | 0.039 | 0.030 | 0.009 | 0.005 | 0.002 | 0.001 | 0.086 | 0.003 | 0.007 | 0.004 | 0.005 | 0.068 | 0.019 | 0.009 | 0.008 | 0.011 | 0.009 | 0.015 | 0.048 | 0.009 | 0.033 | 0.006 | 0.022 | 0.010 | 0.002 | 0.001 | 0.008 | 0.068 | 0.020 | 0.015 | 0.022 | 0.014 | 0.002 | 0.132 | 0.051 | 0.071 | 0.010 | 0.174 | 0.023 | 0.094 | 0.059 | 0.075 | 0.027 | 0.042 | 0.003 | 0.003 | 0.003 | 0.001 | 0.010 | 0.002 | 0.008 | 0.000 | 0.000 | 0.000 | 0.136 | 0.035 | 0.045 | 0.000 | 0.000 | 0.002 | 0.000 | 0.008 | 0.013 | 0.022 | 0.003 | 0.009 | 45.853 | 54.147 | 49.929 | 41.345 | 43.541 | 47.848 | 51.995 | 47.315 | 0.228 | 0.251 | 0.273 | 0.248 |
| 1021 | 24.902 | 41 | 0.235 | 0.027 | 0 | 0 | 0.000 | 0 | 38.703 | 43.958 | 64.152 | 26.795 | 32.610 | 43.596 | 41.691 | 72.597 | 29.597 | 73.788 | 57.228 | 85.597 | 57.226 | 60.138 | 44.763 | 34.217 | 49.674 | 46.660 | 60.262 | 57.370 | 42.859 | 63.902 | 67.147 | 56.554 | 39.826 | 65.449 | 51.794 | 48.751 | 50.492 | 41.254 | 57.662 | 62.726 | 51.219 | 42.008 | 40.777 | 43.725 | 46.877 | 56.214 | 47.260 | 71.646 | 33.865 | 51.769 | 46.877 | 60.909 | 38.890 | 62.061 | 48.660 | 52.187 | 37.900 | 57.089 | 43.177 | 52.588 | 41.555 | 37.684 | 40.633 | 35.668 | 55.490 | 43.752 | 0.031 | 0.104 | 0.013 | 0.046 | 0.056 | -0.038 | 0.098 | 0.137 | 0.283 | 0.717 | 0.057 | 0.033 | 0.000 | 0.007 | 0.025 | 0.002 | 0.018 | 0.046 | 0.012 | 0.016 | 0.051 | 0.041 | 0.022 | 0.033 | 0.004 | -0.011 | 0.031 | 0.041 | 0.099 | 0.901 | 0.027 | 0.004 | 0.000 | 0.000 | 0.017 | 0.000 | 0.000 | 0.006 | 0.000 | 0.000 | 0.033 | 0.000 | 0.009 | 0.027 | 0 | 0.629 | 0.715 | 0.767 | 0.591 | 0.235 | 0.900 | 0.541 | 0.164 | 0.102 | 0.046 | 0.016 | 0.037 | 0.000 | 0.003 | 0.059 | 0.074 | 0.134 | 0.079 | 0.050 | 0.073 | 0.006 | 0.248 | 0.167 | 0.044 | 0.015 | 0.017 | 0.013 | 0.008 | 0.067 | 0.042 | 0.024 | 0.008 | 0.006 | 0.005 | 0.084 | 0.001 | 0.002 | 0.000 | 0.003 | 0.108 | 0.032 | 0.018 | 0.008 | 0.025 | 0.011 | 0.025 | 0.034 | 0.018 | 0.009 | 0.007 | 0.024 | 0.012 | 0.009 | 0.000 | 0.002 | 0.076 | 0.024 | 0.024 | 0.025 | 0.008 | 0.004 | 0.146 | 0.031 | 0.104 | 0.013 | 0.158 | 0.018 | 0.081 | 0.064 | 0.057 | 0.034 | 0.015 | 0.003 | 0.003 | 0.002 | 0.001 | 0.008 | 0.003 | 0.002 | 0.000 | 0.000 | 0.002 | 0.139 | 0.039 | 0.032 | 0.002 | 0.000 | 0.001 | 0.000 | 0.027 | 0.004 | 0.027 | 0.001 | 0.005 | 56.218 | 43.782 | 55.761 | 37.229 | 45.748 | 55.989 | 49.410 | 40.373 | 0.239 | 0.292 | 0.258 | 0.211 |
| 505 | 15.781 | 32 | 0.261 | 0.042 | 0 | 0 | 0.000 | 0 | 61.967 | 63.142 | 54.070 | 54.383 | 73.084 | 51.182 | 54.295 | 59.034 | 54.188 | 41.538 | 37.271 | 61.566 | 60.056 | 77.502 | 57.730 | 54.357 | 23.464 | 40.302 | 67.156 | 60.241 | 56.646 | 33.561 | 54.250 | 29.531 | 51.323 | 31.100 | 30.830 | 30.250 | 59.657 | 48.057 | 42.005 | 50.813 | 65.483 | 39.277 | 73.145 | 39.784 | 41.275 | 72.866 | 24.546 | 75.749 | 43.305 | 34.080 | 41.275 | 47.454 | 17.948 | 50.010 | 35.696 | 68.265 | 32.532 | 61.989 | 41.941 | 33.771 | 61.891 | 41.120 | 34.126 | 45.849 | 54.752 | 37.840 | 0.050 | 0.077 | 0.012 | 0.077 | 0.020 | 0.101 | 0.134 | 0.033 | 0.194 | 0.806 | 0.029 | 0.064 | 0.000 | 0.026 | 0.009 | 0.005 | 0.050 | 0.010 | 0.000 | 0.005 | 0.011 | 0.012 | 0.007 | 0.010 | 0.002 | 0.043 | 0.052 | 0.009 | 0.062 | 0.938 | 0.000 | 0.030 | 0.000 | 0.028 | 0.000 | 0.000 | 0.011 | 0.009 | 0.000 | 0.000 | 0.000 | 0.009 | 0.000 | 0.000 | 0 | 0.713 | 0.445 | 0.830 | 0.769 | 0.261 | 0.893 | 0.550 | 0.160 | 0.097 | 0.077 | 0.000 | 0.020 | 0.000 | 0.000 | 0.063 | 0.091 | 0.149 | 0.077 | 0.057 | 0.063 | 0.012 | 0.257 | 0.158 | 0.038 | 0.018 | 0.028 | 0.014 | 0.026 | 0.040 | 0.034 | 0.006 | 0.002 | 0.000 | 0.002 | 0.075 | 0.008 | 0.002 | 0.002 | 0.006 | 0.105 | 0.032 | 0.008 | 0.014 | 0.020 | 0.020 | 0.020 | 0.012 | 0.004 | 0.006 | 0.002 | 0.002 | 0.000 | 0.000 | 0.000 | 0.000 | 0.069 | 0.016 | 0.014 | 0.040 | 0.004 | 0.000 | 0.139 | 0.050 | 0.077 | 0.012 | 0.152 | 0.020 | 0.071 | 0.063 | 0.077 | 0.055 | 0.014 | 0.004 | 0.010 | 0.000 | 0.000 | 0.006 | 0.000 | 0.000 | 0.002 | 0.004 | 0.000 | 0.184 | 0.057 | 0.075 | 0.006 | 0.000 | 0.004 | 0.002 | 0.006 | 0.004 | 0.026 | 0.002 | 0.002 | 55.334 | 44.666 | 53.862 | 52.681 | 53.991 | 54.593 | 49.049 | 48.508 | 0.262 | 0.265 | 0.238 | 0.235 |
| 512 | 11.907 | 43 | 0.193 | 0.030 | 0 | 0 | 0.000 | 0 | 45.410 | 39.472 | 58.285 | 41.857 | 44.310 | 46.742 | 43.511 | 56.757 | 41.269 | 65.974 | 69.961 | 50.533 | 44.820 | 45.925 | 55.585 | 69.404 | 53.919 | 70.143 | 42.592 | 56.086 | 29.349 | 68.986 | 59.109 | 66.598 | 69.189 | 62.769 | 55.869 | 69.903 | 39.169 | 32.934 | 66.935 | 57.483 | 32.704 | 21.636 | 50.547 | 57.325 | 34.806 | 59.791 | 61.319 | 68.343 | 52.262 | 53.011 | 34.806 | 77.160 | 54.014 | 34.193 | 42.159 | 40.997 | 59.516 | 34.837 | 64.702 | 78.985 | 87.677 | 40.853 | 49.523 | 35.629 | 63.283 | 45.713 | 0.035 | 0.148 | 0.023 | 0.053 | 0.078 | 0.022 | 0.119 | 0.097 | 0.233 | 0.767 | 0.019 | 0.077 | 0.000 | 0.007 | 0.003 | 0.015 | 0.013 | 0.018 | 0.002 | 0.008 | 0.033 | 0.029 | 0.013 | 0.007 | 0.002 | 0.001 | 0.021 | 0.020 | 0.041 | 0.959 | 0.000 | 0.021 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.012 | 0.003 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0 | 0.244 | 0.734 | 0.715 | 0.844 | 0.193 | 0.928 | 0.570 | 0.223 | 0.131 | 0.053 | 0.000 | 0.057 | 0.006 | 0.016 | 0.092 | 0.045 | 0.125 | 0.111 | 0.064 | 0.061 | 0.018 | 0.316 | 0.191 | 0.057 | 0.018 | 0.041 | 0.010 | 0.023 | 0.057 | 0.045 | 0.012 | 0.002 | 0.002 | 0.004 | 0.115 | 0.004 | 0.000 | 0.000 | 0.006 | 0.156 | 0.039 | 0.031 | 0.008 | 0.027 | 0.031 | 0.033 | 0.025 | 0.006 | 0.006 | 0.014 | 0.010 | 0.008 | 0.002 | 0.000 | 0.000 | 0.074 | 0.006 | 0.035 | 0.016 | 0.023 | 0.002 | 0.207 | 0.035 | 0.148 | 0.023 | 0.133 | 0.014 | 0.084 | 0.041 | 0.061 | 0.053 | 0.002 | 0.000 | 0.012 | 0.000 | 0.000 | 0.012 | 0.006 | 0.000 | 0.002 | 0.002 | 0.000 | 0.199 | 0.076 | 0.051 | 0.012 | 0.000 | 0.008 | 0.000 | 0.002 | 0.004 | 0.045 | 0.002 | 0.000 | 62.819 | 37.181 | 58.431 | 45.725 | 53.595 | 60.585 | 46.610 | 41.232 | 0.265 | 0.300 | 0.231 | 0.204 |
| 492 | 9.840 | 50 | 0.209 | 0.030 | 0 | 0 | 0.000 | 0 | 61.947 | 51.836 | 59.433 | 54.708 | 59.546 | 60.607 | 61.527 | 47.855 | 59.184 | 46.199 | 51.642 | 57.517 | 48.536 | 30.641 | 57.657 | 60.192 | 48.844 | 53.481 | 50.420 | 63.754 | 48.274 | 56.681 | 53.092 | 60.355 | 52.540 | 56.458 | 39.843 | 61.852 | 55.239 | 48.255 | 49.647 | 51.503 | 53.572 | 59.843 | 61.272 | 71.862 | 40.229 | 33.811 | 79.981 | 40.962 | 66.168 | 68.734 | 40.229 | 62.142 | 77.513 | 54.325 | 82.774 | 37.096 | 58.020 | 38.737 | 44.975 | 34.176 | 58.491 | 48.331 | 39.397 | 56.769 | 53.370 | 38.387 | 0.030 | 0.163 | 0.022 | 0.004 | 0.108 | 0.048 | 0.137 | 0.089 | 0.255 | 0.745 | 0.046 | 0.047 | 0.002 | 0.013 | 0.025 | 0.026 | 0.030 | 0.021 | 0.003 | 0.013 | 0.023 | 0.018 | 0.004 | 0.016 | 0.000 | 0.031 | 0.050 | 0.019 | 0.076 | 0.924 | 0.013 | 0.023 | 0.000 | 0.013 | 0.004 | 0.017 | 0.000 | 0.000 | 0.000 | 0.004 | 0.000 | 0.000 | 0.000 | 0.000 | 0 | 0.311 | 0.974 | 0.290 | 0.525 | 0.209 | 0.923 | 0.571 | 0.203 | 0.112 | 0.004 | 0.006 | 0.096 | 0.006 | 0.000 | 0.091 | 0.043 | 0.126 | 0.112 | 0.053 | 0.053 | 0.026 | 0.323 | 0.209 | 0.047 | 0.024 | 0.016 | 0.030 | 0.024 | 0.067 | 0.039 | 0.024 | 0.006 | 0.004 | 0.006 | 0.148 | 0.000 | 0.002 | 0.000 | 0.006 | 0.112 | 0.030 | 0.008 | 0.020 | 0.020 | 0.018 | 0.024 | 0.014 | 0.004 | 0.002 | 0.004 | 0.014 | 0.002 | 0.008 | 0.000 | 0.004 | 0.071 | 0.014 | 0.024 | 0.012 | 0.022 | 0.014 | 0.215 | 0.030 | 0.163 | 0.022 | 0.144 | 0.020 | 0.059 | 0.069 | 0.039 | 0.030 | 0.004 | 0.000 | 0.006 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.169 | 0.093 | 0.028 | 0.002 | 0.000 | 0.006 | 0.002 | 0.002 | 0.004 | 0.028 | 0.002 | 0.000 | 64.390 | 35.610 | 65.191 | 55.897 | 59.994 | 64.789 | 48.181 | 44.615 | 0.276 | 0.298 | 0.221 | 0.205 |

### Segments: Analyze Scores

The [SALLEE framework](https://docs.receptiviti.com/frameworks/emotions)
offers measures of emotions, so we might see which categories deviate
the most in any of their segments:

``` r
# select the narrower SALLEE categories
emotions <- segmented_text[, grep("^sallee", colnames(segmented_text))[-(1:6)]]

# make contrasts for each segment
contrasts <- matrix(
  rep_len(c(1, 0, 0, 0, 1, 0, 0, 0, 1), nrow(segmented_text) * 3),
  ncol = 3, byrow = TRUE
)

# correlate emotion scores with contrasts
segment_deviations <- abs(cor(emotions, contrasts))

# select the 5 most deviating emotions
most_deviating <- segmented_text[, names(sort(-apply(
  segment_deviations, 1, max
))[1:5])]
```

Now we can look at those categories across segments:

``` r
splot(
  most_deviating ~ segment, segmented_text,
  laby = "Score", title = FALSE, mv.as.x = TRUE, type = "bar"
)
```

![SALLEE scores by
segment](commencement_example_files/figure-html/unnamed-chunk-15-1.svg)

The bar chart displays original values, which offers the clearest view
of how meaningful the differences between segments might be, in addition
to their statistical significance (which offers a rough guide to the
reliability of differences, based on the variance within and between
segments). By looking at the bar graph, you can immediately see that
admiration shows some of the starkest differences between middle and
early/late segments.

``` r
splot(
  scale(most_deviating) ~ segment, segmented_text,
  leg = "out", laby = "Score (Scaled)", title = FALSE, prat = c(4, 1)
)
```

![scaled SALLEE scores by
segment](commencement_example_files/figure-html/unnamed-chunk-16-1.svg)

The line charts, on the other hand, shows standardized values,
effectively zooming in on the differences between segments. This more
clearly shows, for example, that admiration and joy seem to be used as
bookends in commencement speeches, peaking early and late, whereas more
negative and intense emotions such as anger, disgust, and surprise peak
in the middle section.
