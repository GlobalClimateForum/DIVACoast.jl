// Global Variables
let content_loaded = false;
let currentIndex = 0;

// Execute when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    slider(); // Creates and updates the section slider
    if (!content_loaded) {
        buildBlueprint()
    }else{
        hilightCode();
    };
});

// Blueprint 
function buildBlueprint() {
    $.ajax({ url: './blueprint.json', method: 'GET', dataType: 'json' }).done(bp => {

        Object.keys(bp).forEach(section => {

            let content = bp[section].content
            let content_type = bp[section].type
            let content_target = bp[section].target_id

            if (content.length > 0) {
                if (content_type == "ipynb") {
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

function addNBTemplate(nburl, targetID) {
    return new Promise((resolve, reject) => {
        const target = document.getElementById(targetID);
        const htmlurl = 'https://nbviewer.org/urls/' + nburl;
        // const  converted = '<div class="container" style="display:flex; height: 100%"><iframe class="nbembed" frameborder="0" src="' + htmlurl + '"></iframe></div>'
        // target.insertAdjacentHTML("beforebegin", converted);
        // target.innerHTML = '<iframe frameborder="0" src="' + htmlurl + '" id="embededHTML_nbviewer"></iframe>'
        target.innerHTML = '<object type="text/html" data="' + htmlurl + '" id="embededHTML_nbviewer"></object>'

        resolve();
    }).then(() => {
        const embededHTML = document.getElementById("embededHTML_nbviewer")
        embededHTML.addEventListener("load", function () {
            const embededHTMLDoc = embededHTML.contentDocument || embededHTML.contentWindow.document;
            if (embededHTMLDoc) {
                const linkelemt = embededHTMLDoc.createElement('link');
                linkelemt.rel = 'stylesheet';
                linkelemt.type = 'text/css';
                linkelemt.href = './styles/nbviewer_restyle.css';
                embededHTMLDoc.head.appendChild(linkelemt);
            }
        });
    });
}

function addHTMLEmbed(html_path, targetID) {
    return new Promise((resolve, reject) => {
        const target = document.getElementById(targetID);
        target.innerHTML = '<object type="text/html" data="' + html_path + '" id="embededHTML_docs"></object>'
        resolve();
    }).then(() => {
        // apply restyling
        const embededHTML = document.getElementById("embededHTML_docs");
        embededHTML.addEventListener("load", function () {
            const embededHTMLDoc = embededHTML.contentDocument || embededHTML.contentWindow.document;
            if (embededHTMLDoc) {
                const linkelemt = embededHTMLDoc.createElement('link');
                linkelemt.rel = 'stylesheet';
                linkelemt.type = 'text/css';
                linkelemt.href = '../../styles/documenter_restyle.css';
                embededHTMLDoc.head.appendChild(linkelemt);
            }
        });
    }
    )
}


// Section slider
function slider() {
    const slider = document.querySelector('.section_slider');
    const navLinks = document.querySelectorAll('nav a');
    function move_slider(selected) {
        const offset = - currentIndex * 100;
        slider.style.transform = `translateX(${offset}%)`;
        navLinks.forEach(link => {
            let is_current = link.dataset.indexNumber == currentIndex
            let is_selected = link.classList.contains("selected")
            if (is_current && !is_selected){
                link.classList.add("selected")
            } else if (!is_current && is_selected){
                link.classList.remove("selected")
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