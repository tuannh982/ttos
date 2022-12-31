#include <boot/vga.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* The number of columns. */
#define COLUMNS 80
/* The number of lines. */
#define LINES 24
/* The video memory address. */
#define VIDEO 0xB8000
/* X position. */
static int32_t xpos;
/* Y position. */
static int32_t ypos;
/* Point to the video memory. */
static volatile uint8_t *video;
/* vga entry color */
static uint8_t video_entry_color = VGA_COLOR_LIGHT_GREY | VGA_COLOR_BLACK << 4;

void vga_set_bgcolor(vga_color_t color)
{
    video_entry_color = (video_entry_color & 0x0F) | color << 4;
}

void vga_set_txtcolor(vga_color_t color)
{
    video_entry_color = (video_entry_color & 0xF0) | color;
}

void vga_clear(void)
{
    video = (uint8_t *)VIDEO;
    int i;
    for (i = 0; i < COLUMNS * LINES; i++)
    {
        *(video + i * 2) = ' ';
        *(video + i * 2 + 1) = video_entry_color;
    }
    xpos = 0;
    ypos = 0;
}

void vga_putchar_with_color(char c, vga_color_t color)
{
    if (c == '\n' || c == '\r')
    {
    newline:
        xpos = 0;
        ypos++;
        if (ypos >= LINES)
        {
            ypos = 0;
        }
        return;
    }

    *(video + (xpos + ypos * COLUMNS) * 2) = c;
    *(video + (xpos + ypos * COLUMNS) * 2 + 1) = color;

    xpos++;
    if (xpos >= COLUMNS)
    {
        goto newline;
    }
}

void vga_putchar(char c) {
    vga_putchar_with_color(c, video_entry_color);
}