const codeArea = document.getElementById('code');
codeArea.addEventListener('keydown', function(event) {
    if (event.key === 'Tab') {
        event.preventDefault();
        codeArea.setRangeText('   ', codeArea.selectionStart, codeArea.selectionEnd, 'end');
    }
});

fetch('zig-out/bin/emulator.wasm')
    .then(response => response.arrayBuffer())
    .then(bytes => WebAssembly.instantiate(bytes, zigdom.imports))
    .then(zigdom.launch);