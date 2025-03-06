// Initialize global variables
var content_loaded = false;
var currentIndex = 0; // tracks the current slide
var map;

// init embeds
if (!content_loaded) {
    $.when(initEmbeds()).then(() => { content_loaded = true; });
}

function initEmbeds() {
    buildBlueprint()
    exploreMap();
}

// Execute when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    slider(); // Creates and updates the section slider
    controlMap();
});

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
            if (is_current && !is_selected) {
                link.classList.add("selected")
            } else if (!is_current && is_selected) {
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

// Function for the explore Map 
function controlMap() {
    mapFPControl = document.getElementById("fpidInput");
    mapFPControl.addEventListener("change", (event) => jumpToFloodplain(event));

    function jumpToFloodplain(event) {
        console.log(event.target.value)
        map.panTo(new L.LatLng(0, 0));
    }
}

// Embeds from blueprint
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
            const embededHTMLDoc = embededHTML.contentDocument
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

// Explore Map
function initMap(){

    var mapOptions = {
        center: [53.541176, 9.981012], // Initial center of the map
        zoom: 10,  // Initial Zoom Level
        minZoom: 5,
        maxZoom: 18,
        maxBounds: [[-85, -180], [85, 180]],
        maxBoundsViscosity: 1.0
    }
    map = L.map("exploremap", mapOptions)

    // add basemap
    var basemap = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
    L.tileLayer(basemap, { maxZoom: 18 }).addTo(map);

}

function exploreMap() {

    initMap();

    // Define Cluster Layer
    let markersCluster = L.markerClusterGroup({
        animateAddingMarkers: true,
        spiderfyOnMaxZoom: false,
        disableClusteringAtZoom: 16,
        iconCreateFunction: function (cluster) {
            let count = cluster.getChildCount();
            let size = count < 10 ? "small" : count < 100 ? "medium" : "large";

            return L.divIcon({
                html: `<div class="cluster-icon" ${size}>${count}</div>`,
                className: "custom-cluster",
                iconSize: L.point(40, 40)
            });
        }
    });

    // Define custom Icon
    let customIcon = L.icon({
        iconUrl: "./assets/mapmarker_wave.png",
        iconSize: [30, 30],
        iconAnchor: [15, 15],
        popupAnchor: [0, -15]
    });

    
    let geojsonLayer;
    let geojsonData;

    let baththubdata = "./embeds/resmap/bathtub.geojson";

    fetch(baththubdata)
        .then(response => response.json())
        .then(data => {
            geojsonData = data;
            loadVisibleGeoJSON(map.getBounds());
        });

    function loadVisibleGeoJSON(bounds) {
        if (!geojsonData) return;

        let filteredFeatures = geojsonData.features.filter(feature => {
            if (feature.geometry.type === "Point") {
                let [lng, lat] = feature.geometry.coordinates;
                return bounds.contains([lat, lng]);
            }
            return true;
        });

        if (geojsonLayer) {
            map.removeLayer(geojsonLayer);
            markersCluster.clearLayers();
        }

        geojsonLayer = L.geoJSON({ type: "FeatureCollection", features: filteredFeatures }, {
            pointToLayer: function (feature, latlng) {
                let geojsonMarker = L.marker(latlng, { icon: customIcon })
                    .bindPopup(function () {
                        // Access the feature's properties for dynamic data
                        let properties = feature.properties;

                        // Create the chart container inside the popup
                        let popupContent = `
                        <div class="markerpopup">
                            <h3>ID: ${properties.fpid}</h3>
                            <table class="popup-metatable">
                                <tr>
                                 <td>country code</td>
                                <td>${properties.countryid}</td>
                                </tr>
                                <tr>
                                <td>coast length</td>
                                <td>${properties.coast_length}</td>
                                </tr>

                            </table>

                            <h4>Hypsometric Profile</h4>
                            <canvas id="hypsoChart"></canvas>
                        </div>
                    `;

                        // After the popup is opened, render the chart inside the popup
                        setTimeout(() => {
                            renderLineChart(properties); // Pass data to the chart function
                        }, 300); // Delay to ensure popup is fully opened

                        return popupContent;
                    });
                return geojsonMarker;
            }
        });

        markersCluster.addLayer(geojsonLayer);
        map.addLayer(markersCluster);
    }

    map.on("moveend", () => loadVisibleGeoJSON(map.getBounds()));
}


function renderLineChart(data) {
    let elevsteps = ["-5", "-1", "0", "1", "2", "3", "4", "5", "10", "15", "20"];

    var ctx = document.getElementById("hypsoChart").getContext("2d");

    let chartData = elevsteps.map(element => {
        return data[element] !== undefined ? data[element] : null;
    });

    // Create the chart
    var lineChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: elevsteps,
            datasets: [{
                data: chartData,
                borderColor: '#2b3d4f',
                borderWidth: 2,
                fill: false
            }]
        },
        options: {
            responsive: true,
            scales: {
                x: { title: { display: true, text: 'elevation [m]' } },
                y: { title: { display: true, text: 'cummulative area' } }
            },
            plugins: {
                legend: { display: false }
            }
        }
    });
}


