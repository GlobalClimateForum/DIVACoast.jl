// Global Variables
let content_loaded = false;
let currentIndex = 0;

// Execute when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    slider(); // Creates and updates the section slider
    if (!content_loaded) {
        buildBlueprint();
    };
});

// Blueprint 
function addMDTemplate(directory, targetID) {
    const target = document.getElementById(targetID);
    function fetchMarkdown() { return $.ajax({ url: directory, method: 'GET', dataType: 'text' }) };
    fetchMarkdown().done(content => {
        target.innerHTML = marked.parse(content)
    }).fail((jqXHR, textStatus, errorThrown) => {
        console.error('Failed to fetch Markdown file:', textStatus, errorThrown);
        target.innerHTML = '<p>Could not fetch content.</p>'
    });
}

function addNBTemplate(nburl, targetID) {
    const target = document.getElementById(targetID);
    const htmlurl = 'https://nbviewer.org/urls/' + nburl;
    // const  converted = '<div class="container" style="display:flex; height: 100%"><iframe class="nbembed" frameborder="0" src="' + htmlurl + '"></iframe></div>'
    // target.insertAdjacentHTML("beforebegin", converted);
    target.innerHTML = '<iframe frameborder="0" src="' + htmlurl + '"></iframe>'
}

function addHTMLEmbed(html_path, targetID) {
    const target = document.getElementById(targetID);
    target.innerHTML = '<embed type="text/html" src="' + html_path + '"></embed>'
}

function buildBlueprint() {
    $.ajax({ url: './blueprint.json', method: 'GET', dataType: 'json' }).done(bp => {

        Object.keys(bp).forEach(section => {

            let content = bp[section].content
            let content_type = bp[section].type
            let content_target = bp[section].target_id

            if (content.length > 0) {

                if (content_type == "markdown") {
                    content.forEach(file => {
                        let md_path = './templates/' + section + '/' + file
                        addMDTemplate(md_path, content_target);
                    })
                } else if (content_type == "ipynb") {
                    content.forEach(nb_url => {
                        addNBTemplate(nb_url, content_target);
                    });
                } else if (content_type == "html_embed") {
                    content.forEach(html_path => {
                        addHTMLEmbed(html_path, content_target);
                    });
                }
            };
        })
    }).fail((jqXHR, textStatus, errorThrown) => {
        console.error('Failed to fetch Blueprint:', textStatus, errorThrown);
    });
}

// Section slider
function slider() {

    const slider = document.querySelector('.section_slider');
    // const items = document.querySelectorAll('.slider-item');
    const navLinks = document.querySelectorAll('nav a');


    function move_slider(selected) {
        const offset = - currentIndex * 100;
        slider.style.transform = `translateX(${offset}%)`;

        navLinks.forEach(link => {
            if (link.dataset.indexNumber == currentIndex) {
                link.style = "font-weight: bold;border-bottom: 2px solid white;";
            } else {
                link.style = "font-weight: normal; border-bottom: none"
            }
        });

    }

    navLinks.forEach(link => {
        link.addEventListener('click', (event) => {
            currentIndex = parseInt(link.getAttribute('data-index-number'));
            event.preventDefault();
            move_slider();
        });
    });

    move_slider();
}