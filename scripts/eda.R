library(tidyverse)
library(hockeyR)
library(sportyR)
library(broom)

pbp <- load_pbp('2018-19')

# season_rosters <- get_rosters(season = 2019) |> 
#   select(player, position) |> 
#   mutate(player = str_replace(player, " ", ".")) |> 
#   mutate(position_clean = case_when(position == "G" ~ "G",
#                                     str_detect(position, "D") ~ "D",
#                                     TRUE ~ "F"))
# 
# season_rosters |> 
#   count(position_clean, position) |> 
#   arrange(position_clean)
# 
# season_rosters <- season_rosters |> 
#   select(-position) |> 
#   rename(position = position_clean)

glimpse(pbp)

#glimpse(season_rosters)

skater_stats <- calculate_individual(pbp)

glimpse(skater_stats)

#skater_toi <- calculate_toi(pbp)

pbp |>
  filter(event_type %in% c("SHOT","MISSED_SHOT","GOAL")) |>
  filter(season_type == "R" & period_type != "SHOOTOUT") |>
  group_by(player = event_player_1_name, id = event_player_1_id, season) |>
  summarize(
    team = last(event_team_abbr),
    goals = sum(event_type == "GOAL"),
    xg = round(sum(xg, na.rm = TRUE),1),
    gax = goals - xg,
    .groups = "drop"
  ) |>
  arrange(-xg) |>
  slice(1:10)

pbp |> 
  distinct(event_type)

pbp |> 
  distinct(period_type)

pbp |> 
  distinct(strength_state)

pbp |>
  filter(event_type == "PENALTY") |> 
  glimpse()

pbp |>
  filter(event_type == "PENALTY") |> 
  count(secondary_type, sort = T)

pbp |>
  filter(event_type == "PENALTY") |> 
  filter(is.na(event_player_2_name)) |> 
  count(secondary_type, sort = T)

penalty_df <- pbp |>
  filter(event_type == "PENALTY",
         strength_state == "5v5") |> 
  select(strength_state, event_type, secondary_type,
         event_player_1_type, event_player_1_name, event_player_1_id,
         event_player_2_type, event_player_2_name, event_player_2_id)

penalty_df

player_pen_draw <- penalty_df |> 
  drop_na(event_player_2_name) %>% 
  count(event_player_2_name, event_player_2_id, sort = T, name = "penalties_drawn") %>% 
  rename(player = event_player_2_name,
         player_id = event_player_2_id)

player_pen_draw |> 
  ggplot(aes(penalties_drawn)) +
  geom_density(fill = "grey")

player_pen_taken <- penalty_df |> 
  drop_na(event_player_1_name) %>% 
  count(event_player_1_name, event_player_1_id, sort = T, name = "penalties_taken") %>% 
  rename(player = event_player_1_name,
         player_id = event_player_1_id)

player_pen_taken |> 
  ggplot(aes(penalties_taken)) +
  geom_density(fill = "grey")

pbp |>
  filter(event_type %in% c("SHOT","MISSED_SHOT","GOAL")) 

pbp |> 
  filter(event_player_1_name == "Auston.Matthews") |> 
  glimpse()

player_metrics <- pbp |>
  filter(event_type %in% c("SHOT","MISSED_SHOT","GOAL")) |>
  filter(season_type == "R",
         period_type != "SHOOTOUT",
         strength_state == "5v5") |>
  group_by(player = event_player_1_name, player_id = event_player_1_id, season) |>
  summarize(
    team = last(event_team_abbr),
    shots = n(),
    goals = sum(event_type == "GOAL"),
    xg_median = round(median(xg, na.rm = TRUE),4),
    shot_distance_median = round(median(shot_distance, na.rm = TRUE), 4),
    .groups = "drop"
  ) |>
  arrange(-shots)

player_metrics |> 
  pivot_longer(cols = c(shots, goals, xg_median, shot_distance_median)) |> 
  ggplot(aes(value, fill = name)) +
  geom_density() +
  facet_wrap(vars(name), scales = "free")

reg_data <- player_pen_draw |> 
  left_join(player_pen_taken, by = c("player", "player_id")) |> 
  left_join(player_metrics, by = c("player", "player_id")) |> 
  #left_join(season_rosters, by = c("player")) |> 
  #mutate(position = coalesce(position, "unknown")) |> 
  filter(shots >= 100)

glimpse(reg_data)

reg_data |> 
  filter(position == "unknown")

# season_rosters |> 
#   filter(str_detect(player,  "Gabriel"))

reg_data |> 
  pivot_longer(cols = c(shots, goals, xg_median, shot_distance_median, penalties_taken)) |> 
  ggplot(aes(penalties_drawn, value, color = name)) +
  geom_jitter(alpha = .3) +
  geom_smooth() +
  facet_wrap(vars(name), scales = "free", ncol = 3)

lm_model <- lm(penalties_drawn ~ shots + goals + xg_median + shot_distance_median + penalties_taken, data = reg_data)

tidy(lm_model) |> 
  mutate(term = fct_reorder(term, estimate)) |> 
  ggplot(aes(estimate, term)) +
  geom_col()

glance(lm_model)

lm_fitted <- reg_data |> 
  bind_cols(predict(lm_model, reg_data)) |> 
  rename(penalties_drawn_fitted = `...12`) |> 
  mutate(.resid = penalties_drawn - penalties_drawn_fitted)

glimpse(lm_fitted)

lm_fitted |> 
  ggplot(aes(penalties_drawn, penalties_drawn_fitted)) +
  geom_abline() +
  geom_jitter(alpha = .3) +
  geom_smooth() +
  tune::coord_obs_pred()

lm_fitted |> 
  ggplot(aes(penalties_drawn, penalties_drawn_fitted)) +
  geom_abline() +
  geom_jitter(alpha = .3) +
  geom_smooth() +
  tune::coord_obs_pred() +
  facet_wrap(vars(position))

lm_fitted |> 
  ggplot(aes(.resid)) +
  geom_density() +
  geom_vline(xintercept = 0)

lm_fitted |> 
  ggplot(aes(.resid, fill = position)) +
  geom_density(alpha = .3) +
  geom_vline(xintercept = 0)
