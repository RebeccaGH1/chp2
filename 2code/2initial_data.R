library(data.table)
library(dplyr)
library(readxl)
library(geobr)
library(sf)
library(ggplot2)
library(readr)
# -------------------------------
# 1) Shapefiles
# -------------------------------
muni_sf <- geobr::read_municipality(year = 2010, showProgress = TRUE) %>%
  mutate(MUNICIPALITY_CODE = as.character(code_muni))

states_sf <- geobr::read_state(year = 2010, showProgress = TRUE)

# -------------------------------
# 2) Ler dados (aba DATA)
# -------------------------------
file_path <- "G:/My Drive/PhD/proposal/0 bibliography/chp2/data/Copy of municipios.xls"

df <- read_excel(file_path, sheet = "DATA")


# -------------------------------
# 3) Filtrar PAC 1 ou PAC 2
# -------------------------------
df_pac <- df_raw %>%
  filter(pac_1_ou_pac_2 == 1) %>%
  mutate(
    MUNICIPALITY_CODE = as.character(ibge_7)
  )

# ---- 4) Contar quantos códigos únicos IBGE-7 ----
# (após clean_names, costuma virar ibge_7)
n_ibge7 <- df_pac %>%
  distinct(ibge_7) %>%
  nrow()

### means
medias_df <- df_pac %>%
  summarise(
    media_familias_beneficiadas = mean((familias_beneficiadas), na.rm = TRUE),
    media_percent_realizado     = mean((percent_realizado), na.rm = TRUE),
    media_liberado_ve_vr        = mean((liberado_ve_vr), na.rm = TRUE),
    media_contrapartida         = mean((contrapartida), na.rm = TRUE),
    media_investimento_x_z      = mean((investimento_x_z), na.rm = TRUE)
  )

## quantiw value
df_quant <- df_pac %>%
  mutate(
    liberado_ve_vr_num = (liberado_ve_vr),
    q_liberado_ve_vr = ntile(liberado_ve_vr_num, 4)
  )
quantis <- quantile(
  df_quant$liberado_ve_vr_num,
  probs = c(0, 0.25, 0.5, 0.75, 1),
  na.rm = TRUE
)
resumo_quantis <- df_quant %>%
  group_by(q_liberado_ve_vr) %>%
  summarise(
    n = n(),
    media_liberado_ve_vr = mean(liberado_ve_vr_num, na.rm = TRUE),
    mediana_liberado_ve_vr = median(liberado_ve_vr_num, na.rm = TRUE),
    min = min(liberado_ve_vr_num, na.rm = TRUE),
    max = max(liberado_ve_vr_num, na.rm = TRUE),
    .groups = "drop"
  )
library(ggplot2)

ggplot(df_quant, aes(x = factor(q_liberado_ve_vr),
                     y = liberado_ve_vr_num)) +
  geom_boxplot() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    x = "Quartis do valor liberado (VE/VR)",
    y = "Liberado VE/VR",
    title = "Distribuição do valor liberado por quartis"
  ) +
  theme_minimal()

## pizza for the value distributed
library(dplyr)
library(readr)
library(ggplot2)
library(scales)

to_num_pt <- function(x) {
  parse_number(as.character(x),
               locale = locale(decimal_mark = ",", grouping_mark = "."))
}

top_n <- 10  # mude para 15, 20, etc.

muni_pie <- df_pac %>%
  mutate(liberado_ve_vr_num = to_num_pt(liberado_ve_vr)) %>%
  group_by(municipio) %>%
  summarise(liberado_total = sum(liberado_ve_vr_num, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(liberado_total)) %>%
  mutate(rank = row_number()) %>%
  mutate(group = ifelse(rank <= top_n, municipio, "Others")) %>%
  group_by(group) %>%
  summarise(liberado_total = sum(liberado_total, na.rm = TRUE), .groups = "drop") %>%
  mutate(share = liberado_total / sum(liberado_total, na.rm = TRUE)) %>%
  arrange(desc(liberado_total))

ggplot(muni_pie, aes(x = "", y = liberado_total, fill = group)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  labs(
    title = paste0("Share of total federal transfers: Top ", top_n, " municipalities"),
    x = NULL,
    y = NULL,
    fill = "Municipality"
  ) +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank()
  )

###########3 bars
muni_bar <- df_pac %>%
  mutate(liberado_ve_vr_num = to_num_pt(liberado_ve_vr)) %>%
  group_by(MUNICIPALITY_CODE) %>%
  summarise(liberado_total = sum(liberado_ve_vr_num, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(liberado_total)) %>%
  slice_head(n = top_n)

ggplot(muni_bar, aes(x = reorder(MUNICIPALITY_CODE, liberado_total), y = liberado_total)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(
    title = paste0("Top ", top_n, " municipalities by total federal transfers (Liberado VE/VR)"),
    x = "Municipality (IBGE-7 code)",
    y = "Total transferred amount"
  ) +
  theme_minimal()

#############################
library(lubridate)

df_time <- df_pac %>%
  mutate(
    data_assinatura = as.Date(data_de_assinatura)   # POSIXct → Date (seguro)
  ) %>%
  filter(!is.na(data_assinatura)) %>%
  filter(data_assinatura >= as.Date("2007-01-01"))

# contagem por trimestre
df_quarter <- df_time %>%
  mutate(trimestre = floor_date(data_assinatura, unit = "quarter")) %>%
  count(trimestre, name = "n_obras") %>%
  arrange(trimestre)

# Histograma (barras por trimestre)
# Histogram (bars by quarter)
ggplot(df_quarter, aes(x = trimestre, y = n_obras)) +
  geom_col() +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Distribution of projects by quarter (Signature date)",
    x = "Quarter",
    y = "Number of projects"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -------------------------------
# 4) Somar repasse total por município
# -------------------------------
repasse_muni <- df_pac %>%
  mutate(
    MUNICIPALITY_CODE = as.character(MUNICIPALITY_CODE)
  ) %>%
  group_by(MUNICIPALITY_CODE) %>%
  summarise(
    repasse_total = sum(liberado_ve_vr, na.rm = TRUE),
    n_intervencoes = n(),
    .groups = "drop"
  )
# -------------------------------
# 5) Juntar com shapefile
# -------------------------------
muni_sf <- geobr::read_municipality(year = 2010, showProgress = TRUE) %>%
  mutate(MUNICIPALITY_CODE = as.character(code_muni))

muni_map <- muni_sf %>%
  left_join(repasse_muni, by = "MUNICIPALITY_CODE")

# 3) Mapa – cor = $$$ repassado total
ggplot() +
  geom_sf(
    data = muni_map,
    aes(fill = repasse_total / 1000),
    color = NA
  ) +
  geom_sf(
    data = states_sf,
    fill = NA,
    linewidth = 0.3
  ) +
  scale_fill_viridis_c(
    option = "C",
    trans = "sqrt",
    na.value = "grey90",
    name = "Total transferred\n(in thousands)"
  ) +
  labs(
    title = "Municipalities with interventions",
    subtitle = "Color indicates total federal transfers aggregated at the municipality level"
  ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    legend.position = "right"
  )