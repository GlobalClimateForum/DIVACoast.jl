let content_loaded = false;
let currentIndex = 0;
// Execute when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    carousel(); // Creates and updates the section carousel
    if (!content_loaded) {
        buildBlueprint();
        document.getElementById("docs_embed").height = "calc(100vh - var(--header-height))";
        document.getElementById("docs_embed").width = "var(--def-wrapper-width)";
    }
})


// Blueprint 
function addMDTemplate(directory, targetID) {
    const target = document.getElementById(targetID);
    function fetchMarkdown() { return $.ajax({ url: directory, method: 'GET', dataType: 'text' }) };
    fetchMarkdown().done(content => {
        const converted = '<div class="container">' + marked.parse(content); +  '</div>'
        target.insertAdjacentHTML("beforebegin", converted);
    }).fail((jqXHR, textStatus, errorThrown) => {
        console.error('Failed to fetch Markdown file:', textStatus, errorThrown);
        target.innerHTML = '<div class="mdstyle container"><p style="color: red">content could not be loaded.</p></div>'
    });
}

function addNBTemplate(nburl, targetID) {
    const target = document.getElementById(targetID);
    const htmlurl = 'https://nbviewer.org/urls/' + nburl 
    const  converted = '<div class="container notebook"><iframe frameborder="0" class="example" src="' + htmlurl + '"></iframe></div>'
    console.log(converted)
    target.insertAdjacentHTML("beforebegin", converted);
}


// Blueprint
function buildBlueprint() {
    $.ajax({ url: './blueprint.json', method: 'GET', dataType: 'json' }).done(bp => {
        
        Object.keys(bp).forEach(section => {
            
            let content = bp[section].content
            let content_type = bp[section].type
            let content_target = bp[section].target_id

            if (content.length > 0) {

                if (content_type == "markdown"){
                    content.forEach(file => {
                        let md_path = './templates/' + section + '/' + file
                        addMDTemplate(md_path, content_target)
                    })
                } else if (content_type == "ipynb"){
                    content.forEach(nb_url => {
                        addNBTemplate(nb_url, content_target)
                    });
                }
            };
        })
    }).fail((jqXHR, textStatus, errorThrown) => {
        console.error('Failed to fetch Blueprint:', textStatus, errorThrown);
    });
}

// Section Carousel
function carousel() {
    const carousel = document.querySelector('.carousel-slider');
    // const items = document.querySelectorAll('.carousel-item');
    const navLinks = document.querySelectorAll('nav a');

    function moveCarousel(selected) {
        const offset = - currentIndex * 100;
        carousel.style.transform = `translateX(${offset}%)`;
    }

    navLinks.forEach(link => {
        link.addEventListener('click', (event) => {
            currentIndex =  parseInt(link.getAttribute('data-index'));
            event.preventDefault();
            moveCarousel();
        });
    });

    moveCarousel();
}