'''
Class for providings PipedViewer bindings for PyFerret graphical functions.
An instance of the bindings class is created for each PipedViewer created.
The createWindow method of the bindings is used to create a new PipedViewer
for an instance of the bindings. 

This package was developed by the Thermal Modeling and Analysis Project
(TMAP) of the National Oceanographic and Atmospheric Administration's (NOAA)
Pacific Marine Environmental Lab (PMEL).
'''

from pyferret.graphbind.abstractpyferretbindings import AbstractPyFerretBindings
from pipedviewer import PipedViewer

class PViewPyFerretBindings(AbstractPyFerretBindings):
    '''
    PipedViewer bindings for PyFerret graphical functions.  After
    creating an instance of the bindings, the createWindow method
    should be called to associate a new PipedViewer with the
    bindings instance.
    '''
    
    def __init__(self):
        '''
        Create an instance of the the PipedViewer bindings for PyFerret
        graphical functions.  The createWindow method should be called
        to associate a new PipedViewer with these bindings.
        '''
        super(PViewPyFerretBindings, self).__init__()
        self.__window = None

    def createWindow(self, title, width, height, visible):
        '''
        Creates a PyQtPipedViewer.

        Arguments:
           title: display title for the Window
           width: width of the Window, in units of 0.001 inches
           height: height of the Window, in units of 0.001 inches
           visible: display Window on start-up?
        
        Raises a RuntimeError if an active window is already associated
        with these bindings.

        Returns True.
        '''
        if self.__window != None:
            raise RuntimeError("createWindow called from bindings " \
                               "with an active window")
        self.__window = PipedViewer("PyQtPipedViewer")
        self.__window.submitCommand( { "action":"setTitle",
                                      "title":str(title) } )
        self.__window.submitCommand( { "action":"resize",
                                      "width":float(width),
                                      "height":float(height) } )
        if visible:
            self.__window.submitCommand( {"action":"show"} )
        return True

    def deleteWindow(self):
        '''
        Shuts down the PyQtPipedViewer.

        Returns True.
        '''
        self.__window.submitCommand( { "action":"exit" } )
        self.__window.waitForViewerExit()
        self.__window = None
        return True

    def beginView(self, leftfrac, bottomfrac, rightfrac, topfrac,
                  leftcoord, bottomcoord, rightcoord, topcoord):
        '''
        Start a view in the PyQtPipedViewer Window.

        Arguments:
            leftfrac:    [0,1] fraction of the Window width
                         for the left side of the view
            bottomfrac:  [0,1] fraction of the Window height
                         for the bottom side of the view
            rightfrac:   [0,1] fraction of the Window width
                         for the right side of the view
            topfrac:     [0,1] fraction of the Window height
                         for the top side of the view
            leftcoord:   user coordinate
                         for the left side of the view
            bottomcoord: user coordinate
                         for the bottom side of the view
            rightcoord:  user coordinate
                         for the right side of the view
            topcoord:    user coordinate
                         for the top side of the view
        '''
        leftflt = float(leftfrac)
        bottomflt = float(bottomfrac)
        rightflt = float(rightfrac)
        topflt = float(topfrac)
        if (0.0 > leftflt) or (leftflt >= rightflt) or (rightflt > 1.0):
            raise ValueError("leftfrac and rightfrac must be in [0.0, 1.0] " \
                             "with leftfrac < rightfrac")
        if (0.0 > bottomflt) or (bottomflt >= topflt) or (topflt > 1.0):
            raise ValueError("bottomfrac and topfrac must be in [0.0, 1.0] " \
                             "with bottomfrac < topfrac")
        cmnd = { "action":"beginView", 
                 "viewfracs":{"left":leftflt, "bottom":bottomflt,
                              "right":rightflt, "top":topflt},
                 "usercoords":{"left":leftcoord, "bottom":bottomcoord,
                              "right":rightcoord, "top":topcoord} }
        self.__window.submitCommand(cmnd)

    def endView(self):
        '''
        Close a View in the PyQtPipedViewer Window
        '''
        self.__window.submitCommand( { "action":"endView" } )

    def clearWindow(self, fillcolor):
        '''
        Clears the Window of all drawings.  The Window is filled
        (initialized) with fillcolor.
 
        Arguments:
            fillcolor: Color to fill (initialize) the Window
        '''
        if fillcolor:
            # Make a copy of the fillcolor dictionary
            cmnd = dict(fillcolor)
        else:
            cmnd = { }
        cmnd["action"] = "clear"
        self.__window.submitCommand(cmnd)

    def resizeWindow(self, width, height):
        '''
        Sets the current size of the Window.

        Arguments:
            width: width of the Window, in units of 0.001 inches
            height: height of the window in units of 0.001 inches
        '''
        cmnd = { "action":"resize",
                 "width":width,
                 "height":height }
        self.__window.submitCommand(cmnd)

    def windowDpi(self):
        '''
        Returns a two-tuple containing the screen resolution 
        of the Window, in dots per inch, in the horizontal (X)
        and vertical (Y) directions.
        '''
        # TODO: actually get the screen resolution from the window.
        return (144.0, 144.0)

    def showWindow(self, visible = True):
        '''
        Display or hide a Window.

        Arguments:
            visible: display (if True) or
                     hide (if False) the Window
        '''
        if visible:
            cmnd = { "action":"show" }
        else:
            cmnd = { "action":"hide" }
        self.__window.submitCommand(cmnd)

    def saveWindow(self, filename, fileformat = None):
        '''
        Save the contents of the window to a file.

        Arguments:
            filename: name of the file to create
            fileformat: name of the format to use

        If fileformat is None or empty, the fileformat
        is guessed from the filename extension.
        '''
        cmnd = { "action":"save", "filename":filename }
        if fileformat:
            cmnd["fileformat"] = fileformat
        self.__window.submitCommand(cmnd)

    def createColor(self, redfrac, greenfrac, bluefrac, opaquefrac = 1.0):
        '''
        Returns a Color object from fractional [0.0, 1.0]
        intensities of the red, green, and blue channels.
        The opaquefrac is used to set the alpha channel.

        Arguments:
            redfrac: fractional [0.0, 1.0] red intensity
            greenfrac: fractional [0.0, 1.0] green intensity
            bluefrac: fractional [0.0, 1.0] blue intensity
            opaquefrac: fractional [0.0, 1.0] opaqueness
                (0.0 is transparent; 1.0 is opaque) of the color.
                For output that does not support an alpha channel,
                this will be silently ignored and the color will
                be completely opaque.

        Raises an error if unable to create the Color object.
        '''
        if (redfrac < 0.0) or (redfrac > 1.0):
            raise ValueError("redfrac must be a value in [0.0, 1.0]")
        if (greenfrac < 0.0) or (greenfrac > 1.0):
            raise ValueError("greenfrac must be a value in [0.0, 1.0]")
        if (bluefrac < 0.0) or (bluefrac > 1.0):
            raise ValueError("bluefrac must be a value in [0.0, 1.0]")
        if (opaquefrac < 0.0) or (opaquefrac > 1.0):
            raise ValueError("opaquefrac must be a value in [0.0, 1.0]")
        redint = int( 256.0 * redfrac )
        if redint == 256:
            redint = 255
        greenint = int( 256.0 * greenfrac )
        if greenint == 256:
            greenint = 255
        blueint = int( 256.0 * bluefrac )
        if blueint == 256:
            blueint = 255
        colorint = (redint * 256 + greenint) * 256 + blueint
        opaqueint = int( 256.0 * opaquefrac )
        if opaqueint == 256:
            opaqueint = 255
        return { "color":colorint, "alpha":opaqueint }

    def deleteColor(self, color):
        '''
        Delete a Color object created by createColor

        Arguments:
            color: Color to be deleted
        '''
        pass

    def createFont(self, familyname, fontsize, italic = False,
                   bold = False, underlined = False):
        '''
        Returns a Font object.

        Arguments:
            familyname: name of the font family (e.g., "Helvetica", "Times");
                        None or an empty string uses the default font
            fontsize: desired size of the font in View units
            italic: use the italic version of the font?
            bold: use the bold version of the font?
            underlined: use the underlined version of the font?

        Raises an error if unable to create the Font object.
        '''
        fontdict = { "size":fontsize,
                     "italic":italic,
                     "bold":bold,
                     "underlined":underlined }
        if familyname:
            fontdict["family"] = familyname
        return fontdict

    def deleteFont(self, font):
        '''
        Delete a Font object created by createFont

        Arguments:
            font: Font to be deleted
        '''
        pass

    def createPen(self, color, width, style = "solid",
                  capstyle = None, joinstyle = None):
        '''
        Returns a Pen object.

        Arguments:
            color: Color to use
            width: line width in View units
            style: line style name (e.g., "solid", "dash")
            capstyle: end-cap style name (e.g., "square")
            joinstyle: join style name (e.g., "bevel")

        Raises an error if unable to create the Pen object.
        '''
        if color:
            pen = dict(color)
        else:
            pen = { }
        if width:
            pen["width"] = width
        if style:
            pen["style"] = style
        if capstyle:
            pen["capstyle"] = capstyle
        if joinstyle:
            pen["joinstyle"] = joinstyle
        return pen

    def deletePen(self, pen):
        '''
        Delete a Pen object created by createPen

        Arguments:
            pen: Pen to be deleted
        '''
        pass

    def createBrush(self, color, style = "solid"):
        '''
        Returns a Brush object.

        Arguments:
            color: Color to use
            style: fill style name (e.g., "solid", "cross")

        Raises an error if unable to create the Brush object.
        '''
        if color:
            brush = dict(color)
        else:
            brush = { }
        if style:
            brush["style"] = style
        return brush

    def deleteBrush(self, brush):
        '''
        Delete a Brush object created by createBrush

        Arguments:
            brush: Brush to be deleted
        '''
        pass

    def createSymbol(self, symbolname):
        '''
        Returns a Symbol object.

        Arguments:
            symbolname: name of the symbol.
                Currently supported values are:
                '.' (period): filled circle
                'o' (lowercase oh): unfilled circle
                '+': plus mark
                'x' (lowercase ex): x mark
                '*': asterisk
                '^': triangle
                "#": square

        Raises an error if unable to create the Symbol object.
        '''
        return symbolname

    def deleteSymbol(self, symbol):
        '''
        Delete a Symbol object created by createSymbol

        Arguments:
            symbol: Symbol to be deleted
        '''
        pass

    def drawMultiline(self, ptsx, ptsy, pen):
        '''
        Draws connected line segments.

        Arguments:
            ptsx: the X-coordinates of the points in View units
            ptsy: the Y-coordinates of the points in View units
            pen: the Pen to use to draw the line segments
        '''
        if len(ptsx) != len(ptsy):
            raise ValueError("the lengths of ptsx and ptsy are not the same")
        points = list(zip(ptsx, ptsy))
        cmnd = { "action":"drawMultiline",
                 "points":points,
                 "pen":pen }
        self.__window.submitCommand(cmnd)

    def drawPoints(self, ptsx, ptsy, symbol, color, ptsize):
        '''
        Draws discrete points.

        Arguments:
            ptsx: the X-coordinates of the points in View units
            ptsy: the Y-coordinates of the points in View units
            symbol: the Symbol to use to draw a point
            color: color of the Symbol (if None of empty, default color used)
            ptsize: size of the symbol in View units
        '''
        if len(ptsx) != len(ptsy):
            raise ValueError("the lengths of ptsx and ptsy are not the same")
        points = list(zip(ptsx, ptsy))
        if color:
            # make a copy of the color dictionary
            cmnd = dict(color)
        else:
            cmnd = { }
        cmnd["action"] = "drawPoints"
        cmnd["points"] = points
        cmnd["symbol"] = symbol
        cmnd["size"] = ptsize
        self.__window.submitCommand(cmnd)

    def drawPolygon(self, ptsx, ptsy, brush, pen):
        '''
        Draws a polygon.

        Arguments:
            ptsx: the X-coordinates of the points in View units
            ptsy: the Y-coordinates of the points in View units
            brush: the Brush to use to fill the polygon; if None
                    the polygon will not be filled
            pen: the Pen to use to outline the polygon; if None
                    the polygon will not be outlined
        '''
        if len(ptsx) != len(ptsy):
            raise ValueError("the lengths of ptsx and ptsy are not the same")
        points = list(zip(ptsx, ptsy))
        cmnd = { "action":"drawPolygon", "points":points }
        if brush:
            cmnd["fill"] = brush
        if pen:
            cmnd["outline"] = pen
        self.__window.submitCommand(cmnd)

    def drawRectangle(self, left, bottom, right, top, brush, pen):
        '''
        Draws a rectangle.

        Arguments:
            left: the X-coordinate of the left edge in View units
            bottom: the Y-coordinate of the bottom edge in View units
            right: the X-coordinate of the right edge in View units
            top: the Y-coordinate of the top edge in View units
            brush: the Brush to use to fill the polygon; if None
                    the polygon will not be filled
            pen: the Pen to use to outline the polygon; if None
                    the polygon will not be outlined
         '''
        cmnd = { "action":"drawRectangle",
                 "left":left, "bottom":bottom,
                 "right":right, "top": top }
        if brush:
            cmnd["fill"] = brush
        if pen:
            cmnd["outline"] = pen
        self.__window.submitCommand(cmnd)

    def drawMulticolorRectangle(self, left, bottom, right, top,
                                numrows, numcols, colors):
        '''
        Draws a filled rectangle using an array of solid colors.
        The rectangle is divided into a given number of equally
        spaced rows and a number of equally spaced columns.  Each
        of these cells is then filled with a color (using a solid
        brush) from the corresponding element in an array of colors.

        Arguments:
            left: the X-coordinate of the left edge in View units
            bottom: the Y-coordinate of the bottom edge in View units
            right: the X-coordinate of the right edge in View units
            top: the Y-coordinate of the top edge in View units
            numrows: the number of equally spaced rows
                    to subdivide the rectangle into
            numcols: the number of equally spaced columns
                    to subdivide the rectangle into
            colors: a flattened column-major 2-D list of colors
                    specifying the color of the corresponding cell.
                    The first row is at the top, the first column
                    is on the left.
        '''
        cmnd = { "action":"drawMulticolorRectangle",
                 "left":left, "bottom":bottom,
                 "right":right, "top": top,
                 "numrows":numrows, "numcols":numcols,
                 "colors":colors }
        self.__window.submitCommand(cmnd)

    def drawText(self, text, startx, starty, font, color, rotate = 0):
        '''
        Draws text.

        Arguments:
            text: the text string to draw
            startx: the X-coordinate of the beginning baseline
                    of the text in View units
            starty: the Y-coordinate of the beginning baseline
                    of the text in View units
            font: the font to use for the text
            color: the color to use (as a solid brush or pen)
                    for the text
            rotate: the angle of the baseline in degrees
                    clockwise from horizontal
        '''
        cmnd = { "action":"drawText", "text":text,
                 "location":(startx,starty) }
        if font:
            cmnd["font"] = font
        if color:
            pen = dict(color)
            pen["style"] = "solid"
            cmnd["fill"] = pen
        if rotate != 0.0:
            cmnd["rotate"] = rotate
        self.__window.submitCommand(cmnd)



if __name__ == "__main__":
    import time
    import pyferret
    import pyferret.graphbind
    
    # Initiate pyferret, but stay in python
    pyferret.init(None, False)
    # Create a "PyQtPipedViewer" window, with the title "Tester"
    # The follow raises an error or returns None if there is a problem
    bindinst = pyferret.graphbind.createWindow("PyQtPipedViewer", "Tester", 5000, 5000, True)
    # Create the one font that will be used here
    # - default font, 1/5th of the view in size
    myfont = bindinst.createFont(None, 200, False, False, False)
    # Create a list of colors that will be used here
    mycolors = [
            #  0 opaque black
            bindinst.createColor(0.0, 0.0, 0.0, 1.0),
            #  1 opaque white
            bindinst.createColor(1.0, 1.0, 1.0, 1.0),
            #  2 opaque red
            bindinst.createColor(1.0, 0.0, 0.0, 1.0),
            #  3 opaque yellowish
            bindinst.createColor(0.6, 0.5, 0.0, 1.0),
            #  4 opaque green
            bindinst.createColor(0.0, 1.0, 0.0, 1.0),
            #  5 opaque cyan
            bindinst.createColor(0.0, 0.5, 0.5, 1.0),
            #  6 opaque blue
            bindinst.createColor(0.0, 0.0, 1.0, 1.0),
            #  7 opaque magenta
            bindinst.createColor(0.5, 0.0, 0.5, 1.0),
            #  8 translucent black
            bindinst.createColor(0.0, 0.0, 0.0, 0.25),
            #  9 translucent white
            bindinst.createColor(1.0, 1.0, 1.0, 0.25),
            # 10 translucent red
            bindinst.createColor(1.0, 0.0, 0.0, 0.25),
            # 11 translucent yellowish
            bindinst.createColor(0.6, 0.5, 0.0, 0.25),
            # 12 translucent green
            bindinst.createColor(0.0, 1.0, 0.0, 0.25),
            # 13 translucent cyan
            bindinst.createColor(0.0, 0.5, 0.5, 0.25),
            # 14 translucent blue
            bindinst.createColor(0.0, 0.0, 1.0, 0.25),
            # 15 translucent magenta
            bindinst.createColor(0.5, 0.0, 0.5, 0.25),
            # 16 ransparent white background
            bindinst.createColor(1.0, 1.0, 1.0, 0.0),
    ]
    # x and y coordinates of the vertices of a pentagon
    # (roughly) centered in a 1000 x 1000 square
    pentaptsx = ( 504.5, 100.0, 254.5, 754.5, 909.0, )
    pentaptsy = ( 100.0, 393.9, 869.4, 869.4, 393.9, )
    # Clear the window in transparent white
    bindinst.clearWindow(mycolors[16])
    # Create a view in the top left corner
    bindinst.beginView(0.0, 0.5, 0.5, 1.0, 0, 0, 1000, 1000)
    # Draw a translucent black rentagle over most of the view
    mybrush = bindinst.createBrush(mycolors[8], "solid")
    bindinst.drawRectangle(50, 50, 950, 950, mybrush, None)
    bindinst.deleteBrush(mybrush)
    # Draw a opaque blue polygon with solid black outline
    mybrush = bindinst.createBrush(mycolors[6], "solid")
    mypen = bindinst.createPen(mycolors[0], 6, "solid", "round", "round")
    bindinst.drawPolygon(pentaptsx, pentaptsy, mybrush, mypen)
    bindinst.deletePen(mypen)
    bindinst.deleteBrush(mybrush)
    # Draw some red text strings
    bindinst.drawText("y=100", 100, 100, myfont, mycolors[2], 0)
    bindinst.drawText("y=300", 100, 300, myfont, mycolors[2], 0)
    bindinst.drawText("y=500", 100, 500, myfont, mycolors[2], 0)
    bindinst.drawText("y=700", 100, 700, myfont, mycolors[2], 0)
    # End of this view
    bindinst.endView()
    # Window should already be shown, but just to make sure
    bindinst.showWindow(True)
    raw_input("Press Enter to continue")
    # Create a view of almost the whole window
    bindinst.beginView(0.05, 0.05, 0.95, 0.95, 0, 0, 1000, 1000)
    # Draw a translucent multicolor rectangle covering most of the window
    bindinst.drawMulticolorRectangle(50, 50, 950, 950, 2, 3, mycolors[10:])
    # Draw letters indicating the expected colors
    bindinst.drawText("R", 200, 600, myfont, mycolors[0], -45)
    bindinst.drawText("Y", 200, 150, myfont, mycolors[0], -45)
    bindinst.drawText("G", 500, 600, myfont, mycolors[0], -45)
    bindinst.drawText("C", 500, 150, myfont, mycolors[0], -45)
    bindinst.drawText("B", 800, 600, myfont, mycolors[0], -45)
    bindinst.drawText("M", 800, 150, myfont, mycolors[0], -45)
    # End of this view
    bindinst.endView()
    # Window should already be shown, but just to make sure
    bindinst.showWindow(True)
    raw_input("Press Enter to continue")
    # Create a view of the whole window
    bindinst.beginView(0.0, 0.0, 1.0, 1.0, 0, 0, 1000, 1000)
    # Draw points using various symbols
    ptsy = (100, 300, 500, 700, 900)
    ptsx = (100, 100, 100, 100, 100)
    mysymbol = bindinst.createSymbol(".")
    bindinst.drawPoints(ptsx, ptsy, mysymbol, mycolors[0], 50)
    bindinst.deleteSymbol(mysymbol)
    ptsx = (200, 200, 200, 200, 200)
    mysymbol = bindinst.createSymbol("o")
    bindinst.drawPoints(ptsx, ptsy, mysymbol, mycolors[0], 50)
    bindinst.deleteSymbol(mysymbol)
    ptsx = (300, 300, 300, 300, 300)
    mysymbol = bindinst.createSymbol("+")
    bindinst.drawPoints(ptsx, ptsy, mysymbol, mycolors[6], 50)
    bindinst.deleteSymbol(mysymbol)
    ptsx = (400, 400, 400, 400, 400)
    mysymbol = bindinst.createSymbol("x")
    bindinst.drawPoints(ptsx, ptsy, mysymbol, mycolors[0], 50)
    bindinst.deleteSymbol(mysymbol)
    ptsx = (500, 500, 500, 500, 500)
    mysymbol = bindinst.createSymbol("*")
    bindinst.drawPoints(ptsx, ptsy, mysymbol, mycolors[0], 50)
    bindinst.deleteSymbol(mysymbol)
    ptsx = (600, 600, 600, 600, 600)
    mysymbol = bindinst.createSymbol("^")
    bindinst.drawPoints(ptsx, ptsy, mysymbol, mycolors[6], 50)
    bindinst.deleteSymbol(mysymbol)
    ptsx = (700, 700, 700, 700, 700)
    mysymbol = bindinst.createSymbol("#")
    bindinst.drawPoints(ptsx, ptsy, mysymbol, mycolors[0], 50)
    bindinst.deleteSymbol(mysymbol)
    # Draw a white dash line between some of the points
    mypen = bindinst.createPen(mycolors[1], 8, "dash", "round", "round")
    ptsx = (600, 300, 700, 500, 300, 100)
    ptsy = (100, 300, 500, 700, 500, 900)
    bindinst.drawMultiline(ptsx, ptsy, mypen)
    bindinst.deletePen(mypen)
    # End of this view
    bindinst.endView()
    # Window should already be shown, but just to make sure
    bindinst.showWindow(True)
    raw_input("Press Enter to continue")
    try:
        while 1:
            bindinst.deleteColor(mycolors.pop())
    except IndexError:
        pass
    bindinst.deleteFont(myfont)
    bindinst.deleteWindow()
    print "Success"
