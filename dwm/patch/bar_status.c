int
width_status(Bar *bar, BarArg *a)
{
    int w = 0;
    char *text, *s, ch;

    for (text = s = stext; *s; s++) {
        if ((unsigned char)(*s) < ' ') {
            ch = *s;
            *s = '\0';
            w += TEXTWM(text) - lrpad;
            *s = ch;
            text = s + 1;
        }
    }
    w += TEXTWM(text) - lrpad + 2;

    return w;
}
int
draw_status(Bar *bar, BarArg *a)
{
    int x = a->x;
    char *text, *s, ch;

    for (text = s = stext; *s; s++) {
        if ((unsigned char)(*s) < ' ') {
            ch = *s;
            *s = '\0';

            int w = TEXTWM(text) - lrpad;
            drw_text_status(drw, x, a->y, w, a->h, lrpad / 2, text, 0, True);
            x += w;

            *s = ch;
            text = s + 1;
        }
    }

    int w = TEXTWM(text) - lrpad + 2;
    drw_text_status(drw, x, a->y, w, a->h, lrpad / 2, text, 0, True);

    return 1;
}


int
click_status(Bar *bar, Arg *arg, BarArg *a)
{
    int x = 0;
    char *text, *s, ch;

    statussig = 0;

    for (text = s = stext; *s && x <= a->x; s++) {
        if ((unsigned char)(*s) < ' ') {
            ch = *s;
            *s = '\0';

            x += TEXTWM(text) - lrpad;

            *s = ch;
            text = s + 1;

            if (x >= a->x)
                break;

            if (statussig == ch)
                statussig = 0;
            else
                statussig = ch;
        }
    }

    return ClkStatusText;
}
