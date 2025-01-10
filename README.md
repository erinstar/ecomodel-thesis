# ecomodel-thesis
Code and documentation for my fourth year undergraduate thesis. The model is run in Netlogo, and analysis is done in Python. 

This project contributes to a deeper understanding of habitat patch dynamics and their implications for biodiversity conservation. By managing generalist populations and stabilizing their variability, we can better protect specialist species and promote overall ecosystem resilience.

## The working title is "**Balancing Generalist and Specialist Interactions for Biodiversity Conservation in Fragmented Landscapes**"

**Overview**: Habitat fragmentation significantly impacts biodiversity conservation by altering the interactions between generalist and specialist species. This project utilizes a metacommunity modeling framework in NetLogo to investigate how varying patch sizes and connectivity influence these dynamics over 500 years. The study tests two primary hypotheses regarding the effects of patch size and connectivity on species interactions and offers insights for effective conservation strategies.

**Author**: Erin Ricaloglu
**Affiliation**: Department of Biology, McMaster University, Hamilton, ON, Canada.

**Abstract**: Habitat fragmentation poses significant challenges for biodiversity conservation, particularly in the context of interactions between generalist and specialist species. This study investigates how patch size and connectivity influence these dynamics using a metacommunity modeling framework in NetLogo. Two core hypotheses were tested. First, specialists are disproportionately negatively affected in large habitat patches dominated by generalists due to increased competition and resource depletion. Second, smaller, fragmented patches can promote specialist persistence by creating unique niches and enabling stochastic colonization and dispersal events, which mitigate competitive pressures and support localized survival. Simulating species interactions over 500 years, the model incorporated factors such as dispersal rates, habitat quality, and species specialization to analyze patterns of species turnover and richness. Results demonstrated that large patches favor generalists, intensifying competition and marginalizing specialists. Conversely, smaller, well-connected patches provided critical niches for specialists, underscoring the role of stochastic processes in their survival. These findings suggest that conservation strategies should not focus exclusively on preserving large, contiguous habitats. Instead, a mosaic of smaller, connected patches may be more effective in maintaining biodiversity, particularly in fragmented landscapes. This research provides a refined understanding of habitat patch dynamics, emphasizing the need to manage generalist populations to stabilize ecosystems and protect specialist species. However, the influence of climate change on these dynamics and the long-term stability of fragmented landscapes remains uncertain. Future research should extend these models to include climate-driven scenarios and explore additional factors shaping species interactions in complex ecosystems.


## Workflow

The workflow below outlines the steps taken to develop and analyze the NetLogo model, integrating the two core hypotheses and their respective ecological scenarios.

### Visual Representation

```mermaid
graph TD
    A[Research Objectives] --> B[Formulate Hypotheses]
    B --> C1[Hypothesis 1: Specialists suffer in large patches]
    B --> C2[Hypothesis 2: Small patches promote specialists]
    
    C1 --> D1[Scenario: Two-Level Stability]
    D1 --> D1a[High landscape diversity: beta-diversity high]
    D1 --> D1b[Patch-specific specialization / limited dispersal: alpha-diversity lower]
    D1 --> D1c[Species Sorting]
    
    C2 --> D2[Scenario: One-Level Stability]
    D2 --> D2a[Metapopulation Theory]
    D2 --> D2b[High landscape diversity through source-sink diversity/rescue effects]
    D2 --> D2c[Dynamic Turnover and Coexistence]
    
    C1 & C2 --> E[Model Development in NetLogo]
    E --> F1[Define Agents: Turtles and Patches]
    E --> F2[Implement Processes: Dispersal, Feeding, Interactions]
    E --> F3[Data Logging and Visualization]
    
    E --> G[Simulation Execution]
    G --> H1[Initialize Model]
    G --> H2[Run Simulations Over 500 Years]
    G --> H3[Monitor Outputs]
    
    H3 --> I[Data Analysis]
    I --> J1[Assess Species Turnover and Richness]
    I --> J2[Compare Scenarios to Hypotheses]
    
    I --> K[Draw Conclusions]
    K --> L[Conservation Implications]
    L --> M1[Recommend Mosaic Habitat Strategies]
    L --> M2[Identify Knowledge Gaps]
    
    K --> N[Future Work]
    N --> O1[Extend Models to Include More Factors]
    N --> O2[Optimize Habitat Networks]
