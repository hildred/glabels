/*  window.vala
 *
 *  Copyright (C) 2012  Jim Evins <evins@snaught.com>
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


using GLib;
using libglabels;

namespace glabels
{

	public class Window : Gtk.Window
	{
		private const int DEFAULT_WINDOW_WIDTH  = 1000;
		private const int DEFAULT_WINDOW_HEIGHT = 700;

		private const int ZOOM_INFO_WIDTH   =  75;
		private const int CURSOR_INFO_WIDTH = 150;


		public static unowned List<weak Window> window_list { get; private set; }


		private Prefs               prefs;
		private Ui                  ui;

		public  Model?              model                 { get; private set; }

		private Gtk.Notebook        notebook;

		private Gtk.Box             editor_page_box;
		private Gtk.Box             merge_property_page_box;
		private Gtk.Box             preview_page_box;

		public  View                view                  { get; private set; }
		private ObjectEditor        object_editor;

		public  Gtk.Statusbar       statusbar;
		private Gtk.Label           zoom_info_label;
		private Gtk.Label           cursor_info_label;

		private Gtk.Menu            context_menu;
		private Gtk.Menu            empty_selection_context_menu;

		private MergePropertyEditor merge_property_editor;
		private MiniPreview         preview;


		public Window()
		{
			prefs = new Prefs();
			ui = new Ui( this );

			Gtk.Box vbox1 = new Gtk.Box( Gtk.Orientation.VERTICAL, 0 );
			add( vbox1 );

			vbox1.pack_start( ui.get_widget( "/MenuBar" ), false, false, 0 );
			vbox1.pack_start( ui.get_widget( "/MainToolBar" ), false, false, 0 );

			notebook = new Gtk.Notebook();
			vbox1.pack_start( notebook );


			editor_page_box = new Gtk.Box( Gtk.Orientation.VERTICAL, 0 );
			notebook.append_page( editor_page_box, new Gtk.Label( _("Editor") ) );

			editor_page_box.pack_start( ui.get_widget( "/DrawingToolBar" ), false, false, 0 );
			Gtk.Box hbox1 = new Gtk.Box( Gtk.Orientation.HORIZONTAL, 0 );
			hbox1.set_hexpand( true );
			editor_page_box.pack_start( hbox1, true, true, 0 );

			view = new View();
			hbox1.pack_start( view, true, true, 0 );

			object_editor = new ObjectEditor();
			object_editor.set_hexpand( false );
			hbox1.pack_end( object_editor, false, false, 0 );

			Gtk.Box status_hbox = new Gtk.Box( Gtk.Orientation.HORIZONTAL, 0 );
			editor_page_box.pack_start( status_hbox, false, false, 0 );

			statusbar = new Gtk.Statusbar();
			status_hbox.pack_start( statusbar, true, true, 0 );

			zoom_info_label = new Gtk.Label( null );
			zoom_info_label.set_size_request( ZOOM_INFO_WIDTH, -1 );

			Gtk.Frame zoom_info_frame = new Gtk.Frame( null );
			zoom_info_frame.set_shadow_type( Gtk.ShadowType.IN );
			zoom_info_frame.add( zoom_info_label );
			status_hbox.pack_end( zoom_info_frame, false, false, 0 );

			cursor_info_label = new Gtk.Label( null );
			cursor_info_label.set_size_request( CURSOR_INFO_WIDTH, -1 );

			Gtk.Frame cursor_info_frame = new Gtk.Frame( null );
			cursor_info_frame.set_shadow_type( Gtk.ShadowType.IN );
			cursor_info_frame.add( cursor_info_label );
			status_hbox.pack_end( cursor_info_frame, false, false, 0 );

			this.set_default_size( DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT );

			this.delete_event.connect( on_delete_event );

			context_menu = (Gtk.Menu)ui.get_widget( "/ContextMenu" );
			empty_selection_context_menu = (Gtk.Menu)ui.get_widget( "/EmptySelectionContextMenu" );


			merge_property_page_box = new Gtk.Box( Gtk.Orientation.VERTICAL, 0 );
			notebook.append_page( merge_property_page_box, new Gtk.Label( _("Merge") ) );

			merge_property_editor = new MergePropertyEditor();
			merge_property_page_box.pack_start( merge_property_editor, true, true, 0 );
			

			preview_page_box = new Gtk.Box( Gtk.Orientation.VERTICAL, 0 );
			notebook.append_page( preview_page_box, new Gtk.Label( _("Preview") ) );

			preview = new MiniPreview( 280, 420 );
			preview_page_box.pack_start( preview, true, true, 0 );


			notebook.no_show_all = true;
			notebook.hide();


			window_list.append( this );
		}


		public Window.from_label( Label label )
		{
			this();
			set_label( label );
		}


		public Window.from_file( string filename )
		{
			this();

			string abs_filename = FileUtil.make_absolute( filename );
			Label label = XmlLabel.open_file( abs_filename );

			set_label( label );
		}


		~Window()
		{
			window_list.remove( this );

			if ( window_list.length() == 0 )
			{
				Gtk.main_quit();
			}
		}


		public bool is_empty()
		{
			return model == null;
		}


		public void set_label( Label label )
		{
			model = new Model( label );

			label.modified = false;
			set_window_title( label );

			view.model = model;
			object_editor.set_model( model );
			merge_property_editor.set_model( model );
			preview.set_model( model );

			view.zoom_to_fit();

			view.grid_visible = prefs.grid_visible;
			view.markup_visible = prefs.markup_visible;

			ui.update_all( view );

			string zoom_string = "%3.0f%%".printf( 100*view.zoom );
			zoom_info_label.set_text( zoom_string );

			label.name_changed.connect( on_name_changed );
			label.modified_changed.connect( on_modified_changed );
			label.selection_changed.connect( on_selection_changed );
			label.changed.connect( on_label_changed );
			view.context_menu_activate.connect( on_context_menu_activate );
			view.zoom_changed.connect( on_zoom_changed );
			view.pointer_moved.connect( on_pointer_moved );
			view.pointer_exit.connect( on_pointer_exit );
			this.set_focus.connect( on_set_focus );

			notebook.show();
			editor_page_box.show_all();
			merge_property_page_box.show_all();
			preview_page_box.show_all();

			/* TODO: clipboard changed. */
			/* TODO: set copy/paste sensitivity. */
		}


		private void set_window_title( Label label )
		{
			string name = label.get_short_name();

			if ( label.modified )
			{
				set_title( "%s %s - gLabels".printf( name, _("(modified)") ) );
			}
			else
			{
				set_title( "%s - gLabels".printf( name ) );
			}
		}


		private bool on_delete_event()
		{
			File.close( this );

			return true;
		}


		private void on_selection_changed()
		{
			ui.update_selection_verbs( model, true );
		}


		private void on_context_menu_activate( uint button, uint activate_time )
		{
			if ( model.label.is_selection_empty() )
			{
				empty_selection_context_menu.popup( null, null, null, button, activate_time );
			}
			else
			{
				context_menu.popup( null, null, null, button, activate_time );
			}
		}


		private void on_zoom_changed()
		{
			zoom_info_label.set_text( "%3.0f%%".printf( 100*view.zoom ) );

			ui.update_zoom_verbs( view );
		}


		private void on_pointer_moved( double x,
		                               double y )
		{
			Units units = prefs.units;
			int precision = UnitsUtil.get_precision( units );

			cursor_info_label.set_text( "%.*f, %.*f".printf( precision, x*units.units_per_point,
			                                                 precision, y*units.units_per_point ) );
		}


		private void on_pointer_exit()
		{
			cursor_info_label.set_text( "" );
		}


		private void on_name_changed()
		{
			set_window_title( model.label );
		}


		private void on_modified_changed()
		{
			set_window_title( model.label );
			ui.update_modified_verbs( model );
		}


		private void on_label_changed()
		{
			/* TODO: update undo/redo verbs. */
		}


		private void on_set_focus()
		{
			/* TODO: set copy paste sensitivity. */
		}


	}

}

