/* Python.h should always be first */
#include <Python.h>
#include <string.h>
#include "grdel.h"
#include "cferbind.h"
#include "cairoCFerBind.h"
#include "utf8str.h"

/*
 * Return the text size if drawn to this "Window" using the given font.
 * The value returned at widthptr is amount to advance in X direction 
 * to draw any subsequent text after this text (not the width of the
 * text glyphs as drawn).  The value returned at heightptr is the height 
 * of the text glyphs as drawn.
 *
 * Returns one if successful.   If an error occurs, grdelerrmsg
 * is assigned an appropriate error message and zero is returned.
 */
grdelBool cairoCFerBind_textSize(CFerBind *self, const char *text, int textlen,
                                 grdelType font, double *widthptr, double *heightptr)
{
    CairoCFerBindData *instdata;
    CCFBFont *fontobj;
    char *utf8str;
    int utf8strlen;
#ifdef USEPANGOCAIRO
    PangoLayout *layout;
    int pangowidth;
    int pangoheight;
#else
    cairo_font_extents_t fontextents;
    cairo_text_extents_t textextents;
#endif
    cairo_status_t result;

    /* Sanity check */
    if ( (self->enginename != CairoCFerBindName) &&
         (self->enginename != PyQtCairoCFerBindName) ) {
        strcpy(grdelerrmsg, "cairoCFerBind_textSize: unexpected error, "
                            "self is not a valid CFerBind struct");
        return 0;
    }
    instdata = (CairoCFerBindData *) self->instancedata;
    if ( instdata->context == NULL ) {
        /* Create the Cairo Surface and Context if they do not exist */
        if ( ! cairoCFerBind_createSurface(self) ) {
            /* grdelerrmsg already assigned */
            return 0;
        }
    }
    fontobj = (CCFBFont *) font;
    if ( fontobj->id != CCFBFontId ) {
        strcpy(grdelerrmsg, "cairoCFerBind_textSize: unexpected error, "
                            "font is not CCFBFont struct");
        return 0;
    }
    if ( textlen < 1 ) {
        strcpy(grdelerrmsg, "cairoCFerBind_textSize: textlen is not positive");
        return 0;
    }

    /* Convert to a null-terminated UTF-8 string (convert characters > 0x7F) */
    utf8str = (char *) PyMem_Malloc((2*textlen + 1) * sizeof(char));
    if ( utf8str == NULL ) {
        strcpy(grdelerrmsg, "cairoCFerBind_textSize: "
                            "out of memory for a UTF-8 copy of the text string");
        return 0;
    }
    text_to_utf8_(text, &textlen, utf8str, &utf8strlen);

    /* Get the extents of this text if drawn using the given font */
    cairo_save(instdata->context);
#ifdef USEPANGOCAIRO
    layout = pango_cairo_create_layout(instdata->context);
    pango_layout_set_font_description(layout, fontobj->fontdesc);
    pango_layout_set_text(layout, text, textlen);
    pango_layout_get_size(layout, &pangowidth, &pangoheight);
    g_object_unref(layout);
    *widthptr = (double) pangowidth / PANGO_SCALE;
    *heightptr = (double) pangoheight / PANGO_SCALE;
#else
    cairo_set_font_face(instdata->context, fontobj->fontface);
    cairo_set_font_size(instdata->context, fontobj->fontsize);
    cairo_font_extents(instdata->context, &fontextents);
    cairo_text_extents(instdata->context, utf8str, &textextents);
    *widthptr = textextents.x_advance;
    *heightptr = fontextents.height;
#endif
    result = cairo_status(instdata->context);
    cairo_restore(instdata->context);

    PyMem_Free(utf8str);

    if ( result != CAIRO_STATUS_SUCCESS ) {
        strcpy(grdelerrmsg, "cairoCFerBind_textSize: "
                            "getting the text size was not successful");
        return 0;
    }

    return 1;
}
