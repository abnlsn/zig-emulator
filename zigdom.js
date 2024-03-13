var stackElements = [[], []];
var currentCode = "";

// init stacks
const st = [document.getElementById("stack1"), document.getElementById("stack2")];

for (let i = 0; i < 2; i++) {
  for (let j = 0; j < 16; j++) {
    const div = document.createElement("div");
    div.classList.add("stack-element");
    stackElements[i].push(div)
    st[i].appendChild(div);
  }
}

const getString = function(ptr, len) {
  const slice = zigdom.exports.memory.buffer.slice(ptr, ptr + len);
  const textDecoder = new TextDecoder();
  return textDecoder.decode(slice);
};

const getUint8Array = function(ptr, len) {
  return new Uint8Array(zigdom.exports.memory.buffer, ptr, len);
}

const pushObject = function(object) {
  return zigdom.objects.push(object);
};

const getObject = function(objId) {
  return zigdom.objects[objId - 1];
};

const dispatch = function(eventId) {
  return function() {
    zigdom.exports.dispatchEvent(eventId);
  };
};

const elementSetAttribute = function(
  node_id,
  name_ptr,
  name_len,
  value_ptr,
  value_len
) {
  const node = getObject(node_id);
  const attribute_name = getString(name_ptr, name_len);
  const value = getString(value_ptr, value_len);
  node[attribute_name] = value;
};

const compileBtn = document.getElementById("compile");

compileBtn.addEventListener("click", function(event) {
  const area = document.getElementById("code");
  const text = area.value;
  currentCode = text;

  const textEncoder = new TextEncoder();
  const resultArray = textEncoder.encode(text);
  const len = resultArray.length;

  if (len === 0) {
    return false;
  }

  const ptr = zigdom.exports._wasm_alloc(len);
  if (ptr === 0) {
    throw "Cannot allocate memory";
  }

  // write the array to the memory
  const mem_result = new DataView(zigdom.exports.memory.buffer, ptr, len);
  for (let i = 0; i < len; ++i) {
    mem_result.setUint8(i, resultArray[i], true);
  }

  zigdom.exports.load_code(ptr, len);
})

function hasCompiled() {
  return currentCode === document.getElementById("code").value;
}

const stepBtn = document.getElementById("step");
stepBtn.addEventListener("click", function(event) {
  if (!hasCompiled()) {
    compileBtn.click();
  }
  zigdom.exports.step_cpu();
});

const runBtn = document.getElementById("run");
runBtn.addEventListener("click", function(event) {
  if (!hasCompiled()) {
    compileBtn.click();
  }
  zigdom.exports.run_cpu();
});

const loadStack = function(
  stack_ptr,
  stack_len,
  stack_number,
) {
  const stack = getUint8Array(stack_ptr, stack_len);
  for (let i = 0; i < 16; i++) {
    let pos = stack[i];
    if (i >= stack_len) pos = " ";
    stackElements[stack_number][i].innerText = pos;
  }
}

const elementGetAttribute = function(
  node_id,
  name_ptr,
  name_len,
  result_address_ptr,
  result_address_len_ptr
) {
  const node = getObject(node_id);
  const attribute_name = getString(name_ptr, name_len);
  const result = node[attribute_name];
  // convert result into Uint8Array
  const textEncoder = new TextEncoder();
  const resultArray = textEncoder.encode(result);
  var len = resultArray.length;

  if (len === 0) {
    return false;
  }

  // allocate required number of bytes
  const ptr = zigdom.exports._wasm_alloc(len);
  if (ptr === 0) {
    throw "Cannot allocate memory";
  }

  // write the array to the memory
  const mem_result = new DataView(zigdom.exports.memory.buffer, ptr, len);
  for (let i = 0; i < len; ++i) {
    mem_result.setUint8(i, resultArray[i], true);
  }

  // write the address of the result array to result_address_ptr
  const mem_result_address = new DataView(
    zigdom.exports.memory.buffer,
    result_address_ptr,
    32 / 8
  );
  mem_result_address.setUint32(0, ptr, true);

  //write the size of the result array to result_address_ptr_len_ptr
  const mem_result_address_len = new DataView(
    zigdom.exports.memory.buffer,
    result_address_len_ptr,
    32 / 8
  );
  mem_result_address_len.setUint32(0, len, true);

  // return if success? (optional)
  return true;
};
const eventTargetAddEventListener = function(
  objId,
  event_ptr,
  event_len,
  eventId
) {
  const node = getObject(objId);
  const ev = getString(event_ptr, event_len);
  node.addEventListener(ev, dispatch(eventId));
};

const documentQuerySelector = function(selector_ptr, selector_len) {
  const selector = getString(selector_ptr, selector_len);
  return pushObject(document.querySelector(selector));
};

const documentCreateElement = function(tag_name_ptr, tag_name_len) {
  const tag_name = getString(tag_name_ptr, tag_name_len);
  return pushObject(document.createElement(tag_name));
};

const documentCreateTextNode = function(data_ptr, data_len) {
  data = getString(data_ptr, data_len);
  return pushObject(document.createTextNode(data));
};

const nodeAppendChild = function(node_id, child_id) {
  const node = getObject(node_id);
  const child = getObject(child_id);

  if (node === undefined || child === undefined) {
    return 0;
  }

  return pushObject(node.appendChild(child));
};

const windowAlert = function(msg_ptr, msg_len) {
  const msg = getString(msg_ptr, msg_len);
  alert(msg);
};

const zigReleaseObject = function(object_id) {
  zigdom.objects[object_id - 1] = undefined;
};

const launch = function(result) {
  zigdom.exports = result.instance.exports;
  if (!zigdom.exports.launch_export()) {
    throw "Launch Error";
  }
};

const console_log = function(msg_ptr, msg_len) {
  const msg = getString(msg_ptr, msg_len);
  console.log(msg);
}

var zigdom = {
  objects: [],
  imports: {
    document: {
      query_selector: documentQuerySelector,
      create_element: documentCreateElement,
      create_text_node: documentCreateTextNode
    },
    element: {
      set_attribute: elementSetAttribute,
      get_attribute: elementGetAttribute
    },
    event_target: {
      add_event_listener: eventTargetAddEventListener
    },
    node: {
      append_child: nodeAppendChild
    },
    window: {
      alert: windowAlert,
      console_log: console_log
    },
    zig: {
      release_object: zigReleaseObject
    },
    code: {
      load_stack: loadStack
    }
  },
  launch: launch,
  exports: undefined
};