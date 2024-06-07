## About jdiva
>jdiva is a julia library for economic modelling of coastal sea-level rise impacts and adaptation. It provides a complete tool chain from geodatatypes to datatypes that allow different approaches of coasplain modelling to algorithms that compute flood impacts, erosion and wetland change. The jdiva library is provided by: [Global Climate Forum](https://globalclimateforum.org/)

## Concept
>![jDIVA concept](./templates/about/diva_concept.svg)

>The jdiva library follows a hierarchical and modular structure. At the top of the structure is the `ComposedImpactModel`, a data structure that contains several `LocalCoastalImpactModels`. Each `LocalCoastalImpactModel` consists of an 'exposure' module and a 'scenario' module. The main data structure behind the 'exposure' module is the `HypsometricProfile`. This data structure not only holds the elevation variable of the model but also connects elevation with certain assets, such as population and monetary assets. The 'scenario' module, on the other hand, handles future socio-economic and/or sea level rise scenarios in the form of distributions or by using implemented SLR-/SSP-wrappers.