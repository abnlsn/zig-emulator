// https://github.com/shritesh/zig-wasm-dom
extern "document" fn query_selector(selector_ptr: [*]const u8, selector_len: usize) usize;
extern "document" fn create_element(tag_name_ptr: [*]const u8, tag_name_len: usize) usize;
extern "document" fn create_text_node(data_ptr: [*]const u8, data_len: usize) usize;
extern "element" fn set_attribute(element_id: usize, name_ptr: [*]const u8, name_len: usize, value_ptr: [*]const u8, value_len: usize) void;
extern "element" fn get_attribute(element_id: usize, name_ptr: [*]const u8, name_len: usize, value_ptr: *[*]u8, value_len: *usize) bool;
extern "event_target" fn add_event_listener(event_target_id: usize, event_ptr: [*]const u8, event_len: usize, event_id: usize) void;
extern "window" fn alert(msg_ptr: [*]const u8, msg_len: usize) void;
extern "window" fn log(msg_ptr: [*]const u8, msg_len: usize) void;
extern "node" fn append_child(node_id: usize, child_id: usize) usize;
extern "zig" fn release_object(object_id: usize) void;

const std = @import("std");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

const eventId = enum(usize) {
    Submit,
    Clear,
};

var textarea_node: usize = undefined;

fn launch() !void {
    const body_selector = "body";
    const body_node = query_selector(body_selector, body_selector.len);
    defer release_object(body_node);

    if (body_node == 0) {
        return error.QuerySelectorError;
    }
    const input_tag_name = "div";
    const input_tag_node = create_element(input_tag_name, input_tag_name.len);
    defer release_object(input_tag_node);

    if (input_tag_node == 0) {
        return error.CreateElementError;
    }

    const attribute_name = "innerText";
    const attribute_value = "hello world";

    set_attribute(input_tag_node, attribute_name.ptr, attribute_name.len, attribute_value.ptr, attribute_value.len);

    const attached_input_node = append_child(body_node, input_tag_node);
    defer release_object(attached_input_node);

    if (attached_input_node == 0) {
        return error.AppendChildError;
    }

    const textarea_selector = "#code";
    textarea_node = query_selector(textarea_selector.ptr, textarea_selector.len);
    const textarea_value_name = "value";
    var textarea_value: [*]u8 = undefined;
    var textarea_len: usize = undefined;
    const success = get_attribute(textarea_node, textarea_value_name.ptr, textarea_value_name.len, &textarea_value, &textarea_len);

    if (success) {
        const result = textarea_value[0..textarea_len];
        defer std.heap.page_allocator.free(result);

        log(result.ptr, result.len);
    }

}

export fn load_code(code_ptr: [*]u8, code_len: usize) void {
    // const result = code_ptr[0..code_len];
    // defer std.heap.page_allocator.free(result);

    // log(result.ptr, result.len);
    log(code_ptr, code_len);
}

export fn launch_export() bool {
    launch() catch {
        return false;
    };
    return true;
}

export fn _wasm_alloc(len: usize) u32 {
    const buf = std.heap.page_allocator.alloc(u8, len) catch {
        return 0;
    };
    return @intFromPtr(buf.ptr);
}