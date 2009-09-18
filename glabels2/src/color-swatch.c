/*
 *  color-swatch.c
 *  Copyright (C) 2009  Jim Evins <evins@snaught.com>.
 *
 *  This file is part of gLabels.
 *
 *  gLabels is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  gLabels is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with gLabels.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <config.h>

#include "color-swatch.h"

#include "color.h"
#include "marshal.h"


/*===========================================*/
/* Private macros and constants.             */
/*===========================================*/


/*===========================================*/
/* Private types                             */
/*===========================================*/

struct _glColorSwatchPrivate {

        guint      color;

};


/*===========================================*/
/* Private globals                           */
/*===========================================*/


/*===========================================*/
/* Local function prototypes                 */
/*===========================================*/

static void       gl_color_swatch_finalize    (GObject        *object);

static void       style_set_cb                (GtkWidget      *widget,
                                               GtkStyle       *previous_style);

static void       redraw                      (glColorSwatch  *this);

static gboolean   expose_event_cb             (GtkWidget      *widget,
                                               GdkEventExpose *event);

static void       draw_swatch                 (glColorSwatch  *this,
                                               cairo_t        *cr);



/****************************************************************************/
/* Boilerplate Object stuff.                                                */
/****************************************************************************/
G_DEFINE_TYPE (glColorSwatch, gl_color_swatch, GTK_TYPE_DRAWING_AREA);


/*****************************************************************************/
/* Class Init Function.                                                      */
/*****************************************************************************/
static void
gl_color_swatch_class_init (glColorSwatchClass *class)
{
	GObjectClass   *gobject_class = G_OBJECT_CLASS (class);
	GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (class);

        gl_color_swatch_parent_class = g_type_class_peek_parent (class);

	gobject_class->finalize    = gl_color_swatch_finalize;

        widget_class->expose_event = expose_event_cb;
        widget_class->style_set    = style_set_cb;
}


/*****************************************************************************/
/* Object Instance Init Function.                                            */
/*****************************************************************************/
static void
gl_color_swatch_init (glColorSwatch *this)
{
        GTK_WIDGET_SET_FLAGS (GTK_WIDGET (this), GTK_NO_WINDOW);

	this->priv = g_new0 (glColorSwatchPrivate, 1);
}


/*****************************************************************************/
/* Finalize Method.                                                          */
/*****************************************************************************/
static void
gl_color_swatch_finalize (GObject *object)
{
	glColorSwatch *this = GL_COLOR_SWATCH (object);

	g_return_if_fail (object != NULL);
	g_return_if_fail (GL_IS_COLOR_SWATCH (object));

	g_free (this->priv);

	G_OBJECT_CLASS (gl_color_swatch_parent_class)->finalize (object);
}


/*****************************************************************************/
/** New Object Generator.                                                    */
/*****************************************************************************/
GtkWidget *
gl_color_swatch_new (gint         w,
                     gint         h,
                     guint        color)
{
	glColorSwatch *this;

	this = g_object_new (GL_TYPE_COLOR_SWATCH, NULL);

        this->priv->color = color;

        gtk_widget_set_size_request (GTK_WIDGET (this), w, h);

	return GTK_WIDGET (this);
}


/*****************************************************************************/
/* Set color.                                                                */
/*****************************************************************************/
void
gl_color_swatch_set_color (glColorSwatch *this,
                           guint          color)
{
        this->priv->color = color;

        redraw (this);
}


/*--------------------------------------------------------------------------*/
/* Style set handler (updates colors when style/theme changes).             */
/*--------------------------------------------------------------------------*/
static void
style_set_cb (GtkWidget        *widget,
              GtkStyle         *previous_style)
{
        redraw (GL_COLOR_SWATCH (widget));
}


/*****************************************************************************/
/* Request redraw.                                                           */
/*****************************************************************************/
static void
redraw (glColorSwatch  *this)
{
	GdkRegion *region;

        if (GTK_WIDGET_REALIZED (GTK_WIDGET (this)))
        {
                /* redraw the cairo canvas forcing an expose event */
                region = gdk_drawable_get_clip_region (GTK_WIDGET (this)->window);
                gdk_window_invalidate_region (GTK_WIDGET (this)->window, region, TRUE);
                gdk_region_destroy (region);
        }
}


/*****************************************************************************/
/* "Expose event" callback.                                                  */
/*****************************************************************************/
static gboolean
expose_event_cb (GtkWidget      *widget,
                 GdkEventExpose *event)
{
	cairo_t *cr;

	cr = gdk_cairo_create (widget->window);

	cairo_rectangle (cr,
			event->area.x, event->area.y,
			event->area.width, event->area.height);
	cairo_clip (cr);

        cairo_translate (cr, widget->allocation.x, widget->allocation.y);

	draw_swatch (GL_COLOR_SWATCH (widget), cr);

	cairo_destroy (cr);

	return FALSE;
}


/*****************************************************************************/
/* Draw swatch.                                                              */
/*****************************************************************************/
static void
draw_swatch (glColorSwatch *this,
             cairo_t       *cr)
{
        GtkStyle  *style;
        gdouble    w, h;
        guint      fill_color, line_color;


        cairo_set_antialias (cr, CAIRO_ANTIALIAS_NONE);


        w = GTK_WIDGET (this)->allocation.width;
        h = GTK_WIDGET (this)->allocation.height;


        style = gtk_widget_get_style (GTK_WIDGET (this));
        if ( GTK_WIDGET_IS_SENSITIVE (GTK_WIDGET (this)) )
        {
                fill_color = this->priv->color;
                line_color = gl_color_from_gdk_color (&style->fg[GTK_STATE_NORMAL]);
        }
        else
        {
                fill_color = GL_COLOR_NONE;
                line_color = gl_color_from_gdk_color (&style->fg[GTK_STATE_INSENSITIVE]);
        }

        cairo_rectangle( cr, 0, 0, w-1, h-1 );

        cairo_set_source_rgba (cr, GL_COLOR_RGBA_ARGS (fill_color));
        cairo_fill_preserve( cr );

        cairo_set_source_rgb (cr, GL_COLOR_RGB_ARGS (line_color));
        cairo_set_line_width (cr, 1.0);
        cairo_stroke (cr);
}



/*
 * Local Variables:       -- emacs
 * mode: C                -- emacs
 * c-basic-offset: 8      -- emacs
 * tab-width: 8           -- emacs
 * indent-tabs-mode: nil  -- emacs
 * End:                   -- emacs
 */
