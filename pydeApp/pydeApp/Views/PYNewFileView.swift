//
//  PYNewFileView.swift
//  iPyDE
//
//  Created by Huima on 2024/3/19.
//
import SwiftUI

struct PYNewFileView: View {

    @EnvironmentObject var App: MainApp

    @State var targetUrl: String
    @State private var name = ""
    @FocusState private var filenameFieldIsFocused: Bool

    @Environment(\.presentationMode) var presentationMode

    func checkNameValidity() -> Bool {
        if name.contains(":") || name.contains("/") {
            return false
        } else {
            return true
        }
    }

    func createNewFile(lang: Int, useTemplate: Bool = true) async throws {
        var content = ""

        if !useTemplate && (!checkNameValidity() || name.isEmpty) {
            filenameFieldIsFocused = true
            return
        }

        switch lang {
        case 0:
            name = "example.py"
            content = """
                # Created on \(UIDevice.current.name).
                
                print("Hello World!")
                
                """

        case 1:
            name = "example_sdl2.ui.py"
            content = """
                # Created on \(UIDevice.current.name).

                import os
                import sys
                import random
                import ctypes
                import sdl2

                sdl2.SDL_Init(sdl2.SDL_INIT_VIDEO)
                window = sdl2.SDL_CreateWindow(b"Window", 0, 0, 320, 480, 0)

                def draw(window):
                    rect = sdl2.SDL_Rect(
                        60,
                        140,
                        200,
                        200
                    )
                    color = random.randint(0, 0xFFFFFF)
                    winsourface = sdl2.SDL_GetWindowSurface(window)
                    sdl2.SDL_FillRect(winsourface, None, 0xFFFFFF)
                    sdl2.SDL_FillRect(winsourface, rect, color)
                    sdl2.SDL_UpdateWindowSurface(window)

                running = True
                event = sdl2.SDL_Event()
                while running:
                    while sdl2.SDL_PollEvent(ctypes.byref(event)) != 0:
                      if event.type == sdl2.SDL_QUIT:
                          running = False
                          break
                    
                    draw(window)
                    sdl2.SDL_Delay(1000)

                sdl2.SDL_DestroyWindow(window)
                sdl2.SDL_Quit()
                
                
                
                """
        case 2:
            name = "example_pygame.ui.py"
            content = """
                # Created on \(UIDevice.current.name).

                # Import and initialize the pygame library
                import pygame
                pygame.init()

                # Set up the drawing window
                screen = pygame.display.set_mode([500, 500])

                # Run until the user asks to quit
                running = True
                while running:

                    # Did the user click the window close button?
                    for event in pygame.event.get():
                        if event.type == pygame.QUIT:
                            running = False

                    # Fill the background with white
                    screen.fill((255, 255, 255))

                    # Draw a solid blue circle in the center
                    pygame.draw.circle(screen, (0, 0, 255), (250, 250), 75)

                    # Flip the display
                    pygame.display.flip()

                # Done! Time to quit.
                pygame.quit()
                
                
                """
        case 3:
            name = "example_kivy.ui.py"
            content = """
                # Created on \(UIDevice.current.name).

                from kivy.app import App
                from kivy.core.window import Window
                from kivy.uix.floatlayout import FloatLayout
                from kivy.uix.button import Button
                from kivy.uix.label import Label

                class CounterApp(App):
                    def build(self):
                        Window.fullscreen = False
                        Window.size = (320, 480)
                        
                        self.count = 0
                        self.label = Label(text=str(self.count), size_hint=(.1, .1), pos_hint={'x':.45, 'y':.5})

                        layout = FloatLayout()
                        button = Button(text='Add', size_hint=(.3, .1), pos_hint={'x':.7, 'y':0})
                        button.bind(on_press=self.increment_count)

                        layout.add_widget(self.label)
                        layout.add_widget(button)

                        return layout

                    def increment_count(self, instance):
                        self.count += 1
                        self.label.text = str(self.count)

                CounterApp().run()
                
                
                """
        case 4:
            name = "example_imgui.ui.py"
            content = """
                # Created on \(UIDevice.current.name).

                from imgui.integrations.sdl2 import SDL2Renderer
                from sdl2 import *
                import OpenGL.GLES3 as gl
                import ctypes
                import imgui
                import sys


                def main():
                    window, gl_context = impl_pysdl2_init()
                    
                    imgui.create_context()
                    impl = SDL2Renderer(window)

                    show_custom_window = True
                    
                    running = True
                    event = SDL_Event()
                    while running:
                        while SDL_PollEvent(ctypes.byref(event)) != 0:
                            if event.type == SDL_QUIT:
                                running = False
                                break
                            impl.process_event(event)
                        impl.process_inputs()

                        imgui.new_frame()

                        if imgui.begin_main_menu_bar():
                            if imgui.begin_menu("File", True):

                                clicked_quit, selected_quit = imgui.menu_item(
                                    "Quit", "Cmd+Q", False, True
                                )

                                if clicked_quit:
                                    sys.exit(0)

                                imgui.end_menu()
                            imgui.end_main_menu_bar()

                        imgui.show_test_window()

                        if show_custom_window:
                            is_expand, show_custom_window = imgui.begin("Custom window", True)
                            if is_expand:
                                imgui.text("Bars")
                                imgui.text_colored("Eggs", 0.2, 1.0, 0.0)
                            imgui.end()

                        gl.glClearColor(1.0, 1.0, 1.0, 1)
                        gl.glClear(gl.GL_COLOR_BUFFER_BIT)

                        imgui.render()
                        impl.render(imgui.get_draw_data())
                        SDL_GL_SwapWindow(window)

                    impl.shutdown()
                    SDL_GL_DeleteContext(gl_context)
                    SDL_DestroyWindow(window)
                    SDL_Quit()


                def impl_pysdl2_init():
                    width, height = 800, 600
                    window_name = "minimal ImGui/SDL2 example"

                    if SDL_Init(SDL_INIT_VIDEO) < 0:
                        print(
                            "Error: SDL could not initialize! SDL Error: "
                            + SDL_GetError().decode("utf-8")
                        )
                        sys.exit(1)

                    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1)
                    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24)
                    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8)
                    #SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1)
                    #SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1)
                    #SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 8)
                    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0)
                    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
                    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0)
                    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)

                    SDL_SetHint(SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK, b"1")
                    SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, b"1")
                    
                    window = SDL_CreateWindow(
                        window_name.encode("utf-8"),
                        50,
                        50,
                        width,
                        height,
                        SDL_WINDOW_OPENGL)
                    
                    if window is None:
                        print(
                            "Error: Window could not be created! SDL Error: "
                            + SDL_GetError().decode("utf-8")
                        )
                        sys.exit(1)

                    gl_context = SDL_GL_CreateContext(window)
                    if gl_context is None:
                        print(
                            "Error: Cannot create OpenGL Context! SDL Error: "
                            + SDL_GetError().decode("utf-8")
                        )
                        sys.exit(1)
                    
                    SDL_GL_MakeCurrent(window, gl_context)

                    return window, gl_context


                if __name__ == "__main__":
                    main()
                
                
                """
        case 5:
            name = "example_flet.ui.py"
            content = """
                # Created on \(UIDevice.current.name).

                import flet
                from flet import IconButton, Page, Row, TextField, icons
                import logging, os

                logging.basicConfig(level=logging.DEBUG)

                def main(page: Page):
                    page.title = "Flet counter example"
                    page.vertical_alignment = "center"

                    txt_number = TextField(value="0", text_align="right", width=100)

                    def minus_click(e):
                        txt_number.value = int(txt_number.value) - 1
                        page.update()

                    def plus_click(e):
                        txt_number.value = int(txt_number.value) + 1
                        page.update()

                    page.add(
                        Row(
                            [
                                IconButton(icons.REMOVE, on_click=minus_click),
                                txt_number,
                                IconButton(icons.ADD, on_click=plus_click),
                            ],
                            alignment="center",
                        )
                    )

                flet.app(target=main)
                
                
                """
        case 6:
            name = "example_toga.ui.py"
            content = """
                # Created on \(UIDevice.current.name)
                
                import toga

                class MyApp(toga.App):
                    def startup(self):
                        self.main_window = toga.MainWindow()
                        self.main_window.content = toga.Box(children=[toga.Label("Hello!")])
                        self.main_window.show()

                if __name__ == '__main__':
                    app = MyApp("Realistic App", "org.beeware.realistic")
                    app.main_loop()
                
                
                """
        case 11:
            name = "example_flask.py"
            content = """
                # Created on \(UIDevice.current.name)
                
                from flask import Flask
                import webbrowser

                app = Flask(__name__)

                @app.route("/")
                def hello_world():
                    return "<p>Hello, World!</p>"

                webbrowser.open('http://127.0.0.1:5000')
                app.run()
                
                """
        case 12:
            name = "example_django.py"
            content = """
                # Created on \(UIDevice.current.name)
                
                import sys
                
                from django.conf import settings
                from django.urls import path
                from django.http import HttpResponse
                
                import webbrowser
                
                settings.configure(
                    DEBUG=True,  # For debugging
                    SECRET_KEY="a-bad-secret",  # Insecure! change this
                    ROOT_URLCONF=__name__,
                )
                
                def home(request):
                    return HttpResponse("Welcome!")
                
                urlpatterns = [
                    path("", home),
                ]
                
                if __name__ == "__main__":
                    webbrowser.open('http://127.0.0.1:8080')
                
                    from django.core.management import execute_from_command_line
                    execute_from_command_line(sys.argv + ['runserver', '8080', '--noreload'])
                
                """
        case 20:
            name = "example.c"
            content = """
            // Created on \(UIDevice.current.name)
            
            #include <stdio.h>
            int main() {
                printf("Hello World!\\n");
                return 0;
            }
            """
        case 21:
            name = "example.cpp"
            content = """
            // Created on \(UIDevice.current.name)
            
            #include <iostream>
            
            int main() {
                std::cout << "Hello World!" << std::endl;
                return 0;
            }
            
            """
        case 30:
            name = "example.js"
            content = """
            // Created on \(UIDevice.current.name)
            
            console.log("Hello World!")
            
            """
        case 31:
            name = "index.html"
            content = """
            <!doctype html>
            <html>
              <head>
                <title>Title</title>
                <meta charset="utf-8">
              </head>
              <body>
                <h1>Hello, World</h1>
              </body>
            </html>
            """
        case 32:
            name = "style.css"
            content = """
            /* Applies to the entire body of the HTML document (except where overridden by more specific
            selectors). */
            body {
              margin: 25px;
              background-color: rgb(240,240,240);
              font-family: arial, sans-serif;
              font-size: 14px;
            }

            /* Applies to all <h1>...</h1> elements. */
            h1 {
              font-size: 35px;
              font-weight: normal;
              margin-top: 5px;
            }

            /* Applies to all elements with <... class="someclass"> specified. */
            .someclass { color: red; }

            /* Applies to the element with <... id="someid"> specified. */
            #someid { color: green; }
            """
        case 33:
            name = "package.json"
            content = """
            {
                "name": "proj",
                "version": "1.0.0",
                "description": "proj",
                "main": "index.js",
                "scripts": {
                    "test": "test"
                },
                "keywords": [
                    "proj"
                ],
                "author": "author",
                "license": "ISC"
            }

            """
        case 40:
            name = "example.php"
            content = """
            <?php
                echo "Hello World!\\n"
            ?>
            """
        case 50:
            name = "example.lua"
            content = """
            -- Created on \(UIDevice.current.name)
            
            print("Hello World!\\n")
            """
        case 60:
            name = "example.pl"
            content = """
            print "Hello World!\\n";
            """
        case 62:
            name = "Main.java"
            content = """
                // Created on \(UIDevice.current.name).

                class Main {
                    public static void main(String[] args) {
                        System.out.println("Hello, World!");
                    }
                }
                """
        case 83:
            name = "default.swift"
            content = """
                // Created on \(UIDevice.current.name).

                import Swift
                print("Hello, World!")
                """
        case -2:
            name = "index.html"
            content = """
                <!doctype html>
                <html>
                  <head>
                    <title>Title</title>
                    <meta charset="utf-8">
                  </head>
                  <body>
                    <h1>Hello, World</h1>
                  </body>
                </html>
                """
        case -3:
            name = "style.css"
            content = """
                /* Applies to the entire body of the HTML document (except where overridden by more specific
                selectors). */
                body {
                  margin: 25px;
                  background-color: rgb(240,240,240);
                  font-family: arial, sans-serif;
                  font-size: 14px;
                }

                /* Applies to all <h1>...</h1> elements. */
                h1 {
                  font-size: 35px;
                  font-weight: normal;
                  margin-top: 5px;
                }

                /* Applies to all elements with <... class="someclass"> specified. */
                .someclass { color: red; }

                /* Applies to the element with <... id="someid"> specified. */
                #someid { color: green; }
                """
        default:
            break
        }

        do {
            guard let targetURL = URL(string: targetUrl)?.appendingPathComponent(name) else {
                throw WorkSpaceStorage.FSError.UnableToFindASuitableName
            }
            let destinationURL = try await App.workSpaceStorage.urlWithSuffixIfExistingFileExist(
                url: targetURL)

            try await App.workSpaceStorage.write(
                at: destinationURL, content: content.data(using: .utf8)!, atomically: true,
                overwrite: true
            )
            try await App.openFile(url: destinationURL, alwaysInNewTab: true)
            self.presentationMode.wrappedValue.dismiss()
        } catch {
            App.notificationManager.showErrorMessage(error.localizedDescription)
        }
    }

    struct LanguageTemplateMapping {
        let code: Int
        let name: String
    }

    let languageMappingPython: [LanguageTemplateMapping] = [
        .init(code: 0, name: "Python"),
        .init(code: 1, name: "SDL2"),
        .init(code: 2, name: "PyGame"),
        .init(code: 3, name: "Kivy"),
        .init(code: 4, name: "Imgui"),
        .init(code: 5, name: "Flet"),
        .init(code: 6, name: "Toga"),
        .init(code: 11, name: "Flask"),
        .init(code: 12, name: "Django")
    ]
    
    let languageMapping: [LanguageTemplateMapping] = [
        .init(code: 20, name: "C"),
        .init(code: 21, name: "C++"),
        .init(code: 30, name: "JavaScript"),
        .init(code: 31, name: "Html"),
        .init(code: 32, name: "Css"),
        .init(code: 33, name: "Json"),
        .init(code: 40, name: "Php"),
        .init(code: 50, name: "Lua"),
        .init(code: 60, name: "Perl"),
//        .init(code: 6, name: "Toga"),
//        .init(code: 11, name: "Flask"),
//        .init(code: 12, name: "Django")
    ]

    var body: some View {
        VStack(alignment: .leading) {
            NavigationView {
                Form {
                    Section(header: Text(NSLocalizedString("Templates", comment: ""))) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(languageMappingPython, id: \.code) { language in
                                    Text(language.name)
                                        .onTapGesture {
                                            Task {
                                                try await createNewFile(lang: language.code)
                                            }
                                        }
                                        .padding()
                                        .background(Color.init("B3_A"))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(languageMapping, id: \.code) { language in
                                    Text(language.name)
                                        .onTapGesture {
                                            Task {
                                                try await createNewFile(lang: language.code)
                                            }
                                        }
                                        .padding()
                                        .background(Color.init("B3_A"))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }.listRowSeparator(.hidden)

                    Section(header: Text(NSLocalizedString("Custom", comment: ""))) {
                        HStack {
                            FileIcon(url: name, iconSize: 14)
                                .frame(width: 16)
                                .fixedSize()
                            TextField(
                                "example.py", text: $name,
                                onCommit: {
                                    Task {
                                        try await createNewFile(lang: -1, useTemplate: false)
                                    }
                                }
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($filenameFieldIsFocused)

                            Spacer()
                            Button(action: {
                                Task {
                                    try await createNewFile(lang: -1, useTemplate: false)
                                }
                            }) {
                                Text(NSLocalizedString("Add File", comment: ""))
                            }

                        }

                    }

                    if !checkNameValidity() && name != "" {
                        Text("File name '\(name)' contains invalid character.")
                    }

                    Section(header: Text(NSLocalizedString("Where", comment: ""))) {
                        Text(
                            "\(targetUrl.last == "/" ? targetUrl.dropLast().components(separatedBy: "/").last!.removingPercentEncoding! : targetUrl.components(separatedBy: "/").last!.removingPercentEncoding!)"
                        )
                    }

                }.navigationBarTitle(NSLocalizedString("New File", comment: ""))
            }
            Spacer()
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                filenameFieldIsFocused = true
            }
        }

    }
}

