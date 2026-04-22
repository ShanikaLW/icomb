library(ggplot2)
library(ggimage)
library(dplyr)

# ============================================================
# SETTINGS
# ============================================================
a_small <- 1                 # side length of smallest hexagons
k <- 3                       # each side of a middle hex fits 3 small hexes
a_mid <- k * a_small         # side length of middle hexagons
padding <- a_small     # extra space between middle hexes and outer border

mid_labels <- c("i", "c", "o", "m", "b")
mid_q <- -2:2
mid_r <- rep(0, 5)

# ============================================================
# HELPERS
# ============================================================
hex_vertices <- function(cx, cy, side, id = NA) {
  ang <- seq(90, 390, by = 60) * pi / 180   # pointy-top hexagon
  data.frame(
    id = id,
    x = cx + side * cos(ang),
    y = cy + side * sin(ang)
  )
}

axial_to_xy <- function(q, r, side) {
  data.frame(
    x = sqrt(3) * side * (q + r / 2),
    y = 1.5 * side * r
  )
}

inside_polygon <- function(x, y, poly_x, poly_y) {
  n <- length(poly_x)
  inside <- FALSE
  j <- n
  for (i in seq_len(n)) {
    hit <- ((poly_y[i] > y) != (poly_y[j] > y)) &&
      (x < (poly_x[j] - poly_x[i]) * (y - poly_y[i]) / (poly_y[j] - poly_y[i]) + poly_x[i])
    if (hit) inside <- !inside
    j <- i
  }
  inside
}

# ============================================================
# 1) MIDDLE 5 HEXAGONS
# ============================================================
mid_axial <- data.frame(
  id = 1:5,
  label = mid_labels,
  q = mid_q,
  r = mid_r
)

mid_xy <- axial_to_xy(mid_axial$q, mid_axial$r, a_mid)
mid_centers <- cbind(mid_axial, cx = mid_xy$x, cy = mid_xy$y)
mid_centers$cy <- mid_centers$cy + (0) *1.5 * a_small # for moving the content up by 4 centers

mid_centers$cols <- c("#205CB9", "#CF2C2F", "#F4812E",
                      "#1FB247", "#7B40AF")

mid_hexes <- do.call(
  rbind,
  lapply(seq_len(nrow(mid_centers)), function(i) {
    v <- hex_vertices(mid_centers$cx[i], mid_centers$cy[i], a_mid)
    v$id <- mid_centers$id[i]
    v$cols <- mid_centers$cols[i]   # <-- attach colour here
    v
  })
)



# ============================================================
# 2) OUTER REGULAR HEXAGON
#    Correct sizing using SIDE NORMALS
# ============================================================
all_mid_vertices <- do.call(
  rbind,
  lapply(seq_len(nrow(mid_centers)), function(i) {
    hex_vertices(mid_centers$cx[i], mid_centers$cy[i], a_mid)
  })
)

# Unit normals to the 6 sides of a pointy-top regular hexagon
# (0, 60, 120, 180, 240, 300 degrees)
normal_deg <- seq(0, 300, by = 60)
normals <- cbind(cos(normal_deg * pi / 180), sin(normal_deg * pi / 180))

# For a regular hexagon with side length s:
# apothem = sqrt(3)/2 * s
# A point p is inside iff dot(p, n) <= apothem for all side normals n
max_proj <- max(sapply(seq_len(nrow(normals)), function(i) {
  normals[i, 1] * all_mid_vertices$x + normals[i, 2] * all_mid_vertices$y
}))

a_outer <- (max_proj + padding) / (sqrt(3) / 2)

outer_hex <- hex_vertices(0, 0, a_outer)
outer_hex_plot <- rbind(outer_hex, outer_hex[1, ])

# ============================================================
# 3) SMALL HEX GRID INSIDE OUTER HEXAGON
# ============================================================
R_search <- ceiling(a_outer / a_small) + 8

small_centers <- data.frame()
id <- 1

for (q in -R_search:R_search) {
  for (r in -R_search:R_search) {
    xy <- axial_to_xy(q, r, a_small)

    if (inside_polygon(xy$x, xy$y, outer_hex$x, outer_hex$y)) {
      small_centers <- rbind(
        small_centers,
        data.frame(id = id, q = q, r = r, cx = xy$x, cy = xy$y)
      )
      id <- id + 1
    }
  }
}

small_hexes <- do.call(
  rbind,
  lapply(seq_len(nrow(small_centers)), function(i) {
    hex_vertices(small_centers$cx[i], small_centers$cy[i], a_small, small_centers$id[i])
  })
)

# ============================================================
# PLOT
# ============================================================
outer_hex2 <- outer_hex |>
  mutate(x = x * zoom_outer,
         y = y * zoom_outer)

xmin <- min(outer_hex2$x)
xmax <- max(outer_hex2$x)
ymin <- min(outer_hex2$y)
ymax <- max(outer_hex2$y)

zoom_outer <- 1.05
basicplot <- ggplot() +
  geom_polygon(
    data = outer_hex2,
    aes(x, y),
    fill = "#F9B624",
    colour = NA
  ) +
  geom_polygon(
    data = small_hexes,
    aes(x, y, group = id),
    fill = "#3D3D3D",
    color = "#F9B624",
    linewidth = 0.1
  ) +
  geom_polygon(
    data = mid_hexes,
    aes(x, y, group = id, fill = cols),
    colour = "black",
    linewidth = 1.5
  ) +
  geom_text(
    data = mid_centers,
    aes(cx, cy, label = label),
    size = 14,
    fontface = "bold",
    colour = "white",
    vjust = 0.4
  ) +
  coord_equal(expand = FALSE, xlim = c(xmin, xmax),
              ylim = c(ymin, ymax), clip = "off") +
  theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0)) +
  scale_fill_identity()

bee_centers <- small_hexes |>
  filter(id %in% c(23, 249)) |>
  group_by(id) |>
  summarise(cx = mean(x),
            cy = mean(y)) |>
  mutate(cy = cy + c(0.5, 0),
         image = c("hex/bee.png", "hex/bee_reversed.png"))

basicplot_bees <- basicplot +
  geom_image(data = bee_centers,
             aes(x = cx, y = cy, image = image), size = 0.15)

ratio <- (xmax - xmin) / (ymax - ymin)

ggsave("hex/icomb.pdf", basicplot_bees, width = 5 * ratio, height = 5, dpi = 1200, bg = "transparent")
ggsave("hex/icomb.png", basicplot_bees, width = 5 * ratio, height = 5, dpi = 1200, bg = "transparent")
ggsave("hex/icomb.svg", basicplot_bees, width = 5 * ratio, height = 5, dpi = 1200, bg = "transparent")

