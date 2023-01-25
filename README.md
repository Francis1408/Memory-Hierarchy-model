# Memory-Hierarchy-model
## By Francisco Abreu and Vitor Laguardia

The Memory Hierarchy model is a project built during the lab classes of Computer Architecture. This project aimed to study the data storage dynamic within levels of memory 
inside a computer. As a conquence, we assembled a structure with the following modules:

![Img1](https://github.com/Francis1408/Memory-Hierarchy-model/blob/main/img/Desenho_Projeto.png)


 **Processor (1):** Black box in charge of sending the address (Read and Write) and Data (Write) for the storage modules.
 **Cache (1):**  Associative cache with an 8-bit array divided into two L1 caches, each with 4 blocks. Each block has a 8-bit length, whoch contains the following bit distribution:

 |     [8:8]     |     [7:7]     |     [6:6]     |     [5:3]     |     [2:0]     |
 |---------------|---------------|---------------|---------------|---------------|
 |    VALID      |    LRU        |    DIRTY      |      TAG      |      DATA     |

 * VALID: Bit that tells with the block is empty or not
 * LRU: Bit that tells with that block was the last recent used between it and its pair located on the other L1 cache.
 * DIRTY: Bit thta tells with that block contains an recent information that the lower storage levels do not have.
 * TAG: Associative mapping address between the cache and the memory. The Tag takes the 3 MSB of the Address (5-bit) to map its blocks.
 * DATA: 3-bit space to storage the data 

 **Mux Controller (1):** Module which works a bridge between the Cache and the Memory. Considering the fact that the instructions (Write and Read) take more 
than one cycle to be done, the Mux Controller also works as a state machine.

 **Memory (1):** LPM (auto-generated) memory with an 5-bit address.


