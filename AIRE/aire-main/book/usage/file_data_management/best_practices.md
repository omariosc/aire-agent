(page:best-practices)=
# Best Practices

Follow these guidelines to manage your data efficiently on Aire:

1. **Select the appropriate storage for your task**:  
   - Use **Scratch on Lustre** for large, intermediate datasets.  
   - For single-node, low-latency tasks, use **TMP_LOCAL**.  
   - Choose **TMP_SHARED** or **Flash on Lustre** for I/O-intensive operations requiring temporary, high-speed storage.

2. **Clean up temporary storage**:  
   - Regularly remove unnecessary files from **Scratch on Lustre** to free up space and maintain system performance.

3. **Back up important data**:  
   - Archive critical files externally, as temporary storage is not backed up.  
   - Ensure key results are securely saved to prevent data loss.

4. **Organise and optimise file usage**:
   - Structure directories logically for straightforward data retrieval.  
   - Combine numerous small files into archives (e.g., using `tar`) to enhance performance on Lustre systems.

5. **Monitor your storage usage**:
   - Check your quotas regularly to avoid interruptions:
     - **Home quota**: `quota -s`
     - **Scratch quota**: `lfs quota -h -u $USER /scratch`
     - **Flash quota**: `lfs quota -h -u $USER /flash`
   - Proactive storage management ensures smooth workflows and prevents disruptions during critical tasks.
