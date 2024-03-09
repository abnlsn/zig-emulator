const codeArea = document.getElementById('code');
codeArea.addEventListener('keydown', function(event) {
    if (event.key === 'Tab') {
        event.preventDefault();
        codeArea.setRangeText('   ', codeArea.selectionStart, codeArea.selectionEnd, 'end');
    }
});