# ecomodel-thesis
Code and documentation for my fourth year undergraduate thesis. The model is run in Netlogo, and analysis is done in Python. 

This project contributes to a deeper understanding of habitat patch dynamics and their implications for biodiversity conservation. By managing generalist populations and stabilizing their variability, we can better protect specialist species and promote overall ecosystem resilience. 

## The title is "**How do small habitat patches support higher biodiversity for an equivalent habitat area?**"

**Overview**: Habitat fragmentation significantly impacts biodiversity conservation by altering the interactions between generalist and specialist species. This project utilizes a metacommunity modeling framework in NetLogo to investigate how varying patch sizes and connectivity influence these dynamics over 500 years. The study tests two primary hypotheses regarding the effects of patch size and connectivity on species interactions and offers insights for effective conservation strategies.

**Author**: Erin Ricaloglu
**Affiliation**: Department of Biology, McMaster University, Hamilton, ON, Canada.

**Abstract**: Habitat fragmentation is widely recognized as a threat to biodiversity, yet some studies suggest that small habitat patches can support higher species diversity than larger ones. This study explores the mechanisms behind this phenomenon, focusing on spatial turnover (species replacement between patches) and species sorting with local stability (specialists establishing stable populations in small patches). Using a metacommunity model, we simulated landscapes of 25, 81, and 289 patches, maintaining constant ecological parameters such as species reproduction, movement, and habitat suitability. Each scenario was replicated 30 times over 250 generations, tracking species richness (S), total abundance (N), and turnover rates. Results showed small patches supported nearly twice the species richness of large patches. However, turnover increased over time in large patches, indicating species loss, while small patches maintained stable turnover, suggesting compositional stability. Specialist turnover declined faster than generalists, reinforcing their stability in small patches. Habitat suitability influenced richness differently by patch size: generalist richness increased with suitability in large patches, while specialist richness followed an unimodal pattern. In contrast, small patches showed no clear generalist trend but a unimodal specialist response. These findings indicate that species sorting, rather than high spatial turnover, drives biodiversity in small patches. Small patches act as ecological filters, favouring specialists and stabilizing biodiversity. This challenges the assumption that large, continuous habitats are always superior and highlights the conservation value of small, well-connected patches in fragmented landscapes.

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
