# Extend the official vLLM image
FROM vllm/vllm-openai:latest

# Copy and mark the helper
COPY prefetch-and-run.sh /prefetch-and-run.sh
RUN chmod +x /prefetch-and-run.sh
