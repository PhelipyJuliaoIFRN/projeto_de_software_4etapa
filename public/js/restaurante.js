// Se a imagem cadastrada falhar, preserva o fundo ilustrado do banner.
document.querySelectorAll('.rest img').forEach(img => {
    const falhou = () => { img.hidden = true; };
    img.addEventListener('error', falhou);
    if (img.complete && !img.naturalWidth) falhou();
});
