package main

import "core:mem";
import "core:log";
import "core:strings";
import "core:runtime";

import sdl "vendor:sdl2";
import gl  "vendor:OpenGL";

import imgui "../..";
import imgl  "../../impl/opengl";
import imsdl "../../impl/sdl";

DESIRED_GL_MAJOR_VERSION :: 4;
DESIRED_GL_MINOR_VERSION :: 5;

main :: proc() {
    logger_opts := log.Options {
        .Level,
        .Line,
        .Procedure,
    };
    context.logger = log.create_console_logger(opt = logger_opts);

    log.info("Starting SDL Example...");
    init_err := sdl.Init({.VIDEO});
    defer sdl.Quit();
    if init_err == 0 {
        log.info("Setting up the window...");
        window := sdl.CreateWindow("odin-imgui SDL+OpenGL example", 100, 100, 1280, 720, { .OPENGL, .MOUSE_FOCUS, .SHOWN, .RESIZABLE});
        if window == nil {
            log.debugf("Error during window creation: %s", sdl.GetError());
            sdl.Quit();
            return;
        }
        defer sdl.DestroyWindow(window);

        log.info("Setting up the OpenGL...");
        sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, DESIRED_GL_MAJOR_VERSION);
        sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, DESIRED_GL_MINOR_VERSION);
        sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLprofile.CORE));
        sdl.GL_SetAttribute(.DOUBLEBUFFER, 1);
        sdl.GL_SetAttribute(.DEPTH_SIZE, 24);
        sdl.GL_SetAttribute(.STENCIL_SIZE, 8);
        gl_ctx := sdl.GL_CreateContext(window);
        if gl_ctx == nil {
            log.debugf("Error during window creation: %s", sdl.GetError());
            return;
        }
        sdl.GL_MakeCurrent(window, gl_ctx);
        defer sdl.GL_DeleteContext(gl_ctx);
        if sdl.GL_SetSwapInterval(1) != 0 {
            log.debugf("Error during window creation: %s", sdl.GetError());
            return;
        }
        gl.load_up_to(DESIRED_GL_MAJOR_VERSION, DESIRED_GL_MINOR_VERSION, sdl.gl_set_proc_address);
        gl.ClearColor(0.25, 0.25, 0.25, 1);

        imgui_state := init_imgui_state(window);

        running := true;
        show_demo_window := false;
        e := sdl.Event{};
        for running {
            for sdl.PollEvent(&e) {
                imsdl.process_event(e, &imgui_state.sdl_state);
                #partial switch e.type {
                    case .QUIT:
                        log.info("Got SDL_QUIT event!");
                        running = false;

                    case .KEYDOWN:
                        if is_key_down(e, .ESCAPE) {
                            qe := sdl.Event{};
                            qe.type = .QUIT;
                            sdl.PushEvent(&qe);
                        }
                        if is_key_down(e, .TAB) {
                            io := imgui.get_io();
                            if io.want_capture_keyboard == false {
                                show_demo_window = true;
                            }
                        }
                }
            }

            imgui_new_frame(window, &imgui_state);
            imgui.new_frame();
            {
                info_overlay();

                if show_demo_window do imgui.show_demo_window(&show_demo_window);
                text_test_window();
                input_text_test_window();
                misc_test_window();
                combo_test_window();
            }
            imgui.render();

            io := imgui.get_io();
            gl.Viewport(0, 0, i32(io.display_size.x), i32(io.display_size.y));
            gl.Scissor(0, 0, i32(io.display_size.x), i32(io.display_size.y));
            gl.Clear(gl.COLOR_BUFFER_BIT);
            imgl.imgui_render(imgui.get_draw_data(), imgui_state.opengl_state);
            sdl.GL_SwapWindow(window);
        }
        log.info("Shutting down...");
        
    } else {
        log.debugf("Error during SDL init: (%d)%s", init_err, sdl.GetError());
    }
}

info_overlay :: proc() {
    imgui.set_next_window_pos(imgui.Vec2{10, 10});
    imgui.set_next_window_bg_alpha(0.2);
    overlay_flags: imgui.Window_Flags = .NoDecoration | 
                                        .AlwaysAutoResize | 
                                        .NoSavedSettings | 
                                        .NoFocusOnAppearing | 
                                        .NoNav | 
                                        .NoMove;
    imgui.begin("Info", nil, overlay_flags);
    imgui.text_unformatted("Press Esc to close the application");
    imgui.text_unformatted("Press Tab to show demo window");
    imgui.end();
}

text_test_window :: proc() {
    imgui.begin("Text test");
    imgui.text("NORMAL TEXT: {}", 1);
    imgui.text_colored(imgui.Vec4{1, 0, 0, 1}, "COLORED TEXT: {}", 2);
    imgui.text_disabled("DISABLED TEXT: {}", 3);
    imgui.text_unformatted("UNFORMATTED TEXT");
    imgui.text_wrapped("WRAPPED TEXT: {}", 4);
    imgui.end();
}

input_text_test_window :: proc() {
    imgui.begin("Input text test");
    @static buf: [256]u8;
    @static ok := false;
    imgui.input_text("Test input", buf[:]);
    imgui.input_text("Test password input", buf[:], .Password);
    if imgui.input_text("Test returns true input", buf[:], .EnterReturnsTrue) {
        ok = !ok;
    }
    imgui.checkbox("OK?", &ok);
    imgui.text_wrapped("Buf content: %s", string(buf[:]));
    imgui.end();
}

misc_test_window :: proc() {
    imgui.begin("Misc tests");
    pos := imgui.get_window_pos();
    size := imgui.get_window_size();
    imgui.text("pos: {}", pos);
    imgui.text("size: {}", size);
    imgui.end();
}

combo_test_window :: proc() {
    imgui.begin("Combo tests");
    @static items := []string {"1", "2", "3"};
    @static curr_1 := i32(0);
    @static curr_2 := i32(1);
    @static curr_3 := i32(2);
    if imgui.begin_combo("begin combo", items[curr_1]) {
        for item, idx in items {
            is_selected := idx == int(curr_1);
            if imgui.selectable(item, is_selected) {
                curr_1 = i32(idx);
            }

            if is_selected {
                imgui.set_item_default_focus();
            }
        }
        defer imgui.end_combo();
    }

    imgui.combo_str_arr("combo str arr", &curr_2, items);

    item_getter : imgui.Items_Getter_Proc : proc "c" (data: rawptr, idx: i32, out_text: ^cstring) -> bool {
        context = runtime.default_context();
        items := (cast(^[]string)data);
        out_text^ = strings.clone_to_cstring(items[idx], context.temp_allocator);
        return true;
    }

    imgui.combo_fn_bool_ptr("combo fn ptr", &curr_3, item_getter, &items, i32(len(items)));

    imgui.end();
}

is_key_down :: proc(e: sdl.Event, sc: sdl.Scancode) -> bool {
    return e.key.type == .KEYDOWN && e.key.keysym.scancode == sc;
}

Imgui_State :: struct {
    sdl_state: imsdl.SDL_State,
    opengl_state: imgl.OpenGL_State,
}

init_imgui_state :: proc(window: ^sdl.Window) -> Imgui_State {
    using res := Imgui_State{};

    imgui.create_context();
    imgui.style_colors_dark();

    imsdl.setup_state(&res.sdl_state);
    
    imgl.setup_state(&res.opengl_state);

    return res;
}

imgui_new_frame :: proc(window: ^sdl.Window, state: ^Imgui_State) {
    imsdl.update_display_size(window);
    imsdl.update_mouse(&state.sdl_state, window);
    imsdl.update_dt(&state.sdl_state);
}
