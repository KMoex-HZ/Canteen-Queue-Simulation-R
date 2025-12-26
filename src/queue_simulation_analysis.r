# ================================================================
# Code R Tugas Besar Komputasi Statistik
# Kelompok 5
# ================================================================

# -----------------------------------------------------------------
# Setup
# -----------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)

library(dplyr)
library(lubridate)
library(ggplot2)

# -----------------------------------------------------------------
# FASE 0.5: Data Munging / Wrangling
# -----------------------------------------------------------------
print("Fase 0.5: Membaca dan melakukan data wrangling...")

data_mentah_raw <- NULL

tryCatch({
  data_mentah_raw <- read.csv("~/data_mentah1.csv")
}, error = function(e) {
  print("---!!! ERROR !!!---")
  print("File 'data_mentah1.csv' tidak ditemukan.")
  print("------------------")
})

if (!is.null(data_mentah_raw)) {
  
  data_mentah <- data_mentah_raw %>%
    mutate(
      AT_Awal = hms(AT_Awal),
      SET_Pesan = hms(SET_Pesan),
      SET_Kasir = hms(SET_Kasir),
      AT_Konfirmasi = hms(AT_Konfirmasi),
      SET_Total = hms(SET_Total)
    )
  
  data_awal <- data_mentah %>%
    arrange(AT_Awal) %>%
    mutate(
      IAT_raw = as.numeric(AT_Awal - lag(AT_Awal), units = "secs"),
      ST_Kasir_raw = as.numeric(SET_Kasir - SET_Pesan, units = "secs"),
      ST_Dapur_raw = as.numeric(SET_Total - AT_Konfirmasi, units = "secs")
    ) %>%
    mutate(
      IAT = IAT_raw / 60,
      ST_Kasir = ST_Kasir_raw / 60,
      ST_Dapur = ST_Dapur_raw / 60
    ) %>%
    select(IAT, ST_Kasir, ST_Dapur) %>%
    filter(!is.na(IAT))
  
  write.csv(data_awal, "data_awal.csv", row.names = FALSE)
  
  print("Data wrangling selesai dan data_awal.csv tersimpan.")
  
} else {
  stop("Data mentah kosong. Proses dihentikan.")
}

# -----------------------------------------------------------------
# FASE 1: Pengolahan Data Awal
# -----------------------------------------------------------------
print("Fase 1: Menghitung parameter data awal...")

mean_iat <- mean(data_awal$IAT, na.rm = TRUE)
sd_iat <- sd(data_awal$IAT, na.rm = TRUE)

mean_kasir <- mean(data_awal$ST_Kasir, na.rm = TRUE)
sd_kasir <- sd(data_awal$ST_Kasir, na.rm = TRUE)

mean_dapur <- mean(data_awal$ST_Dapur, na.rm = TRUE)
sd_dapur <- sd(data_awal$ST_Dapur, na.rm = TRUE)

# -----------------------------------------------------------------
# FASE 2: Implementasi Algoritma & Skenario Basis
# -----------------------------------------------------------------
print("Fase 2: Menyiapkan simulasi dan fungsi...")

n_simulasi <- 10000

fungsi_hitung_tis <- function(sim_st_kasir, sim_st_dapur) {
  tis <- sim_st_kasir + sim_st_dapur
  tis[tis < 0] <- 0
  return(tis)
}

# -----------------------------------------------------------------
# FASE 3: Optimasi dan Perulangan Skenario
# -----------------------------------------------------------------
print("Fase 3: Menjalankan Perulangan Skenario...")

hasil_tis_rata2 <- c()
nama_skenario <- c()

for (i in 1:4) {
  
  if (i == 1) {
    nama <- "Skenario 1 (Basis)"
    mean_k_temp <- mean_kasir
    mean_d_temp <- mean_dapur
    
  } else if (i == 2) {
    nama <- "Skenario 2 (Tambah Kasir, Efisiensi +30%)"
    mean_k_temp <- mean_kasir * 0.70
    mean_d_temp <- mean_dapur
    
  } else if (i == 3) {
    nama <- "Skenario 3 (Dapur -15%)"
    mean_k_temp <- mean_kasir
    mean_d_temp <- mean_dapur * 0.85
    
  } else {
    nama <- "Skenario 4 (Dapur -30%)"
    mean_k_temp <- mean_kasir
    mean_d_temp <- mean_dapur * 0.70
  }
  
  sim_kasir <- rnorm(n_simulasi, mean_k_temp, sd_kasir)
  sim_dapur <- rnorm(n_simulasi, mean_d_temp, sd_dapur)
  
  tis_sim <- fungsi_hitung_tis(sim_kasir, sim_dapur)
  
  hasil_tis_rata2 <- c(hasil_tis_rata2, mean(tis_sim))
  nama_skenario <- c(nama_skenario, nama)
  
  cat("Iterasi", i, "selesai |", nama, "\n")
}

# -----------------------------------------------------------------
# FASE 4: Analisis dan Pencarian Minimum Iteratif
# -----------------------------------------------------------------
print("Fase 4: Analisis dan Pencarian Minimum...")

hasil_akhir <- data.frame(
  Skenario = nama_skenario,
  Rata_Rata_TIS = hasil_tis_rata2
)

x <- hasil_akhir$Rata_Rata_TIS
n <- length(x)

nilai_min <- x[1]
indeks_min <- 1

for (i in 2:n) {
  if (x[i] < nilai_min) {
    nilai_min <- x[i]
    indeks_min <- i
  }
}

cat("Nilai minimum TIS:", round(nilai_min, 2), "\n")
cat("Didapat dari:", hasil_akhir$Skenario[indeks_min], "\n")

# -----------------------------------------------------------------
# Visualisasi
# -----------------------------------------------------------------
hasil_akhir$Kode <- paste0("S", seq_len(nrow(hasil_akhir)))

warna_penelitian <- c("#4E79A7", "#F28E2B", "#E15759", "#76B7B2")

ggplot(hasil_akhir, aes(x = Kode, y = Rata_Rata_TIS, fill = Skenario)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = round(Rata_Rata_TIS, 2)), vjust = -0.5) +
  scale_fill_manual(values = warna_penelitian) +
  geom_hline(yintercept = mean(hasil_akhir$Rata_Rata_TIS),
             linetype = "dashed") +
  labs(
    title = "Perbandingan Mean TIS Antar Skenario",
    x = "Skenario",
    y = "Rata-rata TIS (Menit)"
  ) +
  theme_minimal()
