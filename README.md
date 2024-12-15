# ecomodel-thesis
Code and documentation for my fourth year undergraduate thesis. The model is run in Netlogo, and analysis is done in Python. 

This project contributes to a deeper understanding of habitat patch dynamics and their implications for biodiversity conservation. By managing generalist populations and stabilizing their variability, we can better protect specialist species and promote overall ecosystem resilience.

## The working title is "**Balancing Generalist and Specialist Interactions for Biodiversity Conservation in Fragmented Landscapes**"

**Overview**: Habitat fragmentation significantly impacts biodiversity conservation by altering the interactions between generalist and specialist species. This project utilizes a metacommunity modeling framework in NetLogo to investigate how varying patch sizes and connectivity influence these dynamics over 500 years. The study tests two primary hypotheses regarding the effects of patch size and connectivity on species interactions and offers insights for effective conservation strategies.

**Author**: Erin Ricaloglu
**Affiliation**: Department of Biology, McMaster University, Hamilton, ON, Canada.

**Abstract**: Habitat fragmentation presents complex challenges for biodiversity conservation, particularly concerning the interactions between generalist and specialist species. This study explores how varying patch sizes and connectivity influence these dynamics using a metacommunity modeling framework in NetLogo. The objective was to test two core hypotheses: first, that specialists suffer greater negative impacts in large patches dominated by generalists due to increased competition and resource depletion, and second, that smaller, fragmented patches can sometimes promote specialist persistence through stochastic colonization and dispersal events. By simulating species interactions over 500 years, the model incorporated factors such as dispersal rates, habitat quality, and species specialization to assess patterns of species turnover and richness. Results indicate that large patches indeed favor generalists, intensifying competition and marginalizing specialists. However, smaller patches, especially when well-connected, provided niches that supported specialist survival, highlighting the role of stochastic processes. In practice, these findings suggest that conservation strategies should not solely focus on preserving large, contiguous habitats but should consider a mosaic of smaller, connected patches to effectively maintain biodiversity. This approach could offer a more balanced strategy, especially in landscapes where fragmentation is unavoidable. Key benefits of this research include a more refined understanding of habitat patch dynamics and their implications for biodiversity conservation. The study emphasizes the importance of managing generalist populations and stabilizing their variability to protect specialist species. However, questions remain about how climate change will impact these dynamics and the long-term stability of fragmented landscapes. Further research is needed to extend these models to climate-driven scenarios and explore additional factors that influence species interactions in complex ecosystems.

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
