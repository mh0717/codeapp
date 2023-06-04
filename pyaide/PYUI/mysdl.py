#"""The almighty Hello World! example"""
## We'll use sys to properly exit with an error code.
#import os
#import sys
#import sdl2.ext
#
## Create a resource container, so that we can easily access all
## resource, we bundle with our application. We are using the current
## file's location and define the "resources" subdirectory as the
## location, in which we keep all data.
#filepath = os.path.abspath(os.path.dirname(__file__))
#RESOURCES = sdl2.ext.Resources(filepath, "res")
#
#
#def run():
#    # Initialize the video system - this implicitly initializes some
#    # necessary parts within the SDL2 DLL used by the video module.
#    #
#    # You SHOULD call this before using any video related methods or
#    # classes.
#    sdl2.ext.init()
#
#    # Create a new window (like your browser window or editor window,
#    # etc.) and give it a meaningful title and size. We definitely need
#    # this, if we want to present something to the user.
#    window = sdl2.ext.Window("Hello World!", size=(592, 460))
#
#    # By default, every Window is hidden, not shown on the screen right
#    # after creation. Thus we need to tell it to be shown now.
#    window.show()
#
#    # Create a Renderer for the new window, which we can use to copy and
#    # draw things to the screen. Renderers can use hardware-accelerated
#    # backends (e.g. OpenGL, Direct3D) as well as software-accelerated ones,
#    # depending on the flags you create it with.
##    renderflags = sdl2.SDL_RENDERER_SOFTWARE
##    if "-hardware" in sys.argv:
#    renderflags = (
#        sdl2.SDL_RENDERER_ACCELERATED | sdl2.SDL_RENDERER_PRESENTVSYNC
#    )
#    renderer = sdl2.ext.Renderer(window, flags=renderflags)
#
#    # Import an image file and convert it to a Texture. A Texture is an SDL
#    # surface that has been prepared for use with a given Renderer.
#    tst_img = sdl2.ext.load_bmp(RESOURCES.get_path("hello.bmp"))
#    tx = sdl2.ext.Texture(renderer, tst_img)
#
#    # Display the image on the window. This code takes the texture we created
#    # earlier and copies it to the renderer (with the top-left corner of the
#    # texture placed at the coordinates (0, 0) on the window surface), then
#    # takes the contents of the renderer surface and presents them on its
#    # associated window.
#    renderer.copy(tx, dstrect=(0, 0))
#    renderer.present()
#
#    # Create a simple event loop. This fetches the SDL2 event queue and checks
#    # for any quit events. Once a quit event is received, the loop will end
#    # and we'll send the signal to quit the program.
#    running = True
#    while running:
#        events = sdl2.ext.get_events()
#        for event in events:
#            if event.type == sdl2.SDL_QUIT:
#                running = False
#                break
#
#    # Now that we're done with the SDL2 library, we shut it down nicely using
#    # the `sdl2.ext.quit` function.
#    sdl2.ext.quit()
#    return 0
#
#if __name__ == "__main__":
#    sys.exit(run())
#











#"""2D drawing examples."""
#import sys
#from random import randint
#import sdl2
#import sdl2.ext
#
## Draws random lines on the passed surface
#def draw_lines(surface, width, height):
#    # Fill the whole surface with a black color.
#    sdl2.ext.fill(surface, 0)
#    for x in range(15):
#        # Create a set of four random points for drawing the line.
#        x1, x2 = randint(0, width), randint(0, width)
#        y1, y2 = randint(0, height), randint(0, height)
#        # Create a random color.
#        color = sdl2.ext.Color(randint(0, 255),
#                               randint(0, 255),
#                               randint(0, 255))
#        # Draw the line with the specified color on the surface.
#        # We also could create a set of points to be passed to the function
#        # in the form
#        #
#        # line(surface, color, (x1, y1, x2, y2, x3, y3, x4, y4, ...))
#        #                       ^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^
#        #                         first line     second line
#        sdl2.ext.line(surface, color, (x1, y1, x2, y2))
#
#
## Draws random, filled rectangles on the passed surface
#def draw_rects(surface, width, height):
#    # Fill the whole surface with a black color.
#    sdl2.ext.fill(surface, 0)
#    for k in range(15):
#        # Create a set of four random points for the edges of the rectangle.
#        x, y = randint(0, width), randint(0, height)
#        w, h = randint(1, width // 2), randint(1, height // 2)
#        # Create a random color.
#        color = sdl2.ext.Color(randint(0, 255),
#                               randint(0, 255),
#                               randint(0, 255))
#        # Draw the filled rect with the specified color on the surface.
#        # We also could create a set of points to be passed to the function
#        # in the form
#        #
#        # fill(surface, color, ((x1, y1, x2, y2), (x3, y3, x4, y4), ...))
#        #                        ^^^^^^^^^^^^^^    ^^^^^^^^^^^^^^
#        #                          first rect        second rect
#        sdl2.ext.fill(surface, color, (x, y, w, h))
#
#
#def run():
#    # You know those from the helloworld.py example.
#    # Initialize the video subsystem, create a window and make it visible.
#    sdl2.ext.init()
#    window = sdl2.ext.Window("2D drawing primitives", size=(800, 600))
#    window.show()
#
#    # As in colorpalettes.py, explicitly acquire the window's surface to
#    # draw on.
#    windowsurface = window.get_surface()
#
#    # We implement the functionality as it was done in colorpalettes.py and
#    # utilise a mapping table to look up the function to be executed, together
#    # with the arguments they should receive
#    functions = ((draw_lines, (windowsurface, 300, 600)),
#                 (draw_rects, (windowsurface, 300, 600))
#                 )
#
#    # A storage variable for the function we are currently on, so that we know
#    # which function to execute next.
#    curindex = 0
#    draw_lines(windowsurface, 300, 600)
#    window.refresh()
#    # The event loop is nearly the same as we used in colorpalettes.py. If you
#    # do not know, what happens here, take a look at colorpalettes.py for a
#    # detailled description.
#    running = True
#    while running:
#        events = sdl2.ext.get_events()
#        for event in events:
#            if event.type == sdl2.SDL_QUIT:
#                running = False
#                break
#            if event.type == sdl2.SDL_MOUSEBUTTONDOWN:
#                print('pressed')
#                windowsurface = window.get_surface()
#                functions = ((draw_lines, (windowsurface, 300, 600)),
#                             (draw_rects, (windowsurface, 300, 600))
#                            )
#                curindex += 1
#                if curindex >= len(functions):
#                    curindex = 0
#                # In contrast to colorpalettes.py, our mapping table consists
#                # of functions and their arguments. Thus, we get the currently
#                # requested function and argument tuple and execute the
#                # function with the arguments.
#                func, args = functions[curindex]
#                func(*args)
#                window.refresh()
#                break
#
#    sdl2.ext.quit()
#    return 0
#
#
#if __name__ == "__main__":
#    sys.exit(run())









#from kivy.base import runTouchApp
#from kivy.lang import Builder
#
#runTouchApp(Builder.load_string('''
#ActionBar:
#    pos_hint: {'top':1}
#    ActionView:
#        use_separator: True
#        ActionPrevious:
#            title: 'Action Bar'
#            with_previous: False
#        ActionOverflow:
#        ActionButton:
#            icon: 'atlas://data/images/defaulttheme/audio-volume-high'
#        ActionButton:
#            important: True
#            text: 'Important'
#        ActionButton:
#            text: 'Btn2'
#        ActionButton:
#            text: 'Btn3'
#        ActionButton:
#            text: 'Btn4'
#        ActionGroup:
#            text: 'Group1'
#            ActionButton:
#                text: 'Btn5'
#            ActionButton:
#                text: 'Btn6'
#            ActionButton:
#                text: 'Btn7'
#'''))














""" pg.examples.stars

    We are all in the gutter,
    but some of us are looking at the stars.
                                            -- Oscar Wilde

A simple starfield example. Note you can move the 'center' of
the starfield by leftclicking in the window. This example show
the basics of creating a window, simple pixel plotting, and input
event management.
"""
import random
import math
import pygame as pg

# constants
WINSIZE = [640, 480]
WINCENTER = [320, 240]
NUMSTARS = 150


def init_star():
    "creates new star values"
    dir = random.randrange(100000)
    velmult = random.random() * 0.6 + 0.4
    vel = [math.sin(dir) * velmult, math.cos(dir) * velmult]
    return vel, WINCENTER[:]


def initialize_stars():
    "creates a new starfield"
    stars = []
    for x in range(NUMSTARS):
        star = init_star()
        vel, pos = star
        steps = random.randint(0, WINCENTER[0])
        pos[0] = pos[0] + (vel[0] * steps)
        pos[1] = pos[1] + (vel[1] * steps)
        vel[0] = vel[0] * (steps * 0.09)
        vel[1] = vel[1] * (steps * 0.09)
        stars.append(star)
    move_stars(stars)
    return stars


def draw_stars(surface, stars, color):
    "used to draw (and clear) the stars"
    for vel, pos in stars:
        pos = (int(pos[0]), int(pos[1]))
        surface.set_at(pos, color)


def move_stars(stars):
    "animate the star values"
    for vel, pos in stars:
        pos[0] = pos[0] + vel[0]
        pos[1] = pos[1] + vel[1]
        if not 0 <= pos[0] <= WINSIZE[0] or not 0 <= pos[1] <= WINSIZE[1]:
            vel[:], pos[:] = init_star()
        else:
            vel[0] = vel[0] * 1.05
            vel[1] = vel[1] * 1.05


def main():
    "This is the starfield code"
    # create our starfield
    random.seed()
    stars = initialize_stars()
    clock = pg.time.Clock()
    # initialize and prepare screen
    pg.init()
    screen = pg.display.set_mode(WINSIZE)
    pg.display.set_caption("pygame Stars Example")
    white = 255, 240, 200
    black = 20, 20, 40
    screen.fill(black)

    # main game loop
    done = 0
    while not done:
        draw_stars(screen, stars, black)
        move_stars(stars)
        draw_stars(screen, stars, white)
        pg.display.update()
        for e in pg.event.get():
            if e.type == pg.QUIT or (e.type == pg.KEYUP and e.key == pg.K_ESCAPE):
                done = 1
                break
            elif e.type == pg.MOUSEBUTTONDOWN and e.button == 1:
                WINCENTER[:] = list(e.pos)
        clock.tick(50)
    pg.quit()


# if python says run, then we should run
if __name__ == "__main__":
    main()

    # I prefer the time of insects to the time of stars.
    #
    #                              -- Wisława Szymborska
