#!/bin/bash

# AI Prompt Inference System - Bash Wrapper

# Setup and convenience functions for prompt inference

set -euo pipefail

# Configuration

SCRIPT_DIR=”$(cd “$(dirname “${BASH_SOURCE[0]}”)” && pwd)”
PYTHON_SCRIPT=”$SCRIPT_DIR/prompt_inference.py”
VENV_DIR=”$SCRIPT_DIR/venv”
REQUIREMENTS_FILE=”$SCRIPT_DIR/requirements.txt”

# Colors for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
NC=’\033[0m’ # No Color

# Logging functions

log_info() {
echo -e “${BLUE}[INFO]${NC} $1” >&2
}

log_warn() {
echo -e “${YELLOW}[WARN]${NC} $1” >&2
}

log_error() {
echo -e “${RED}[ERROR]${NC} $1” >&2
}

log_success() {
echo -e “${GREEN}[SUCCESS]${NC} $1” >&2
}

# Create requirements.txt if it doesn’t exist

create_requirements() {
if [[ ! -f “$REQUIREMENTS_FILE” ]]; then
cat > “$REQUIREMENTS_FILE” << ‘EOF’
torch>=1.9.0
transformers>=4.21.0
Pillow>=8.0.0
opencv-python>=4.5.0
librosa>=0.8.0
numpy>=1.21.0
scipy>=1.7.0
matplotlib>=3.3.0
requests>=2.25.0
EOF
log_info “Created requirements.txt”
fi
}

# Setup virtual environment and dependencies

setup_environment() {
log_info “Setting up Python environment…”

```
# Create virtual environment if it doesn't exist
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
    log_success "Created virtual environment"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Upgrade pip
pip install --upgrade pip

# Create and install requirements
create_requirements
pip install -r "$REQUIREMENTS_FILE"

log_success "Environment setup complete"
```

}

# Check if environment is properly set up

check_environment() {
if [[ ! -d “$VENV_DIR” ]]; then
log_warn “Virtual environment not found. Run ‘setup’ first.”
return 1
fi

```
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    log_error "Python script not found at $PYTHON_SCRIPT"
    return 1
fi

return 0
```

}

# Activate virtual environment

activate_env() {
if check_environment; then
source “$VENV_DIR/bin/activate”
else
return 1
fi
}

# Quick analysis function

quick_analyze() {
local input_file=”$1”
local output_dir=”${2:-./results}”

```
if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
fi

activate_env || return 1

local basename=$(basename "$input_file")
local output_file="$output_dir/${basename%.*}_analysis.json"

mkdir -p "$output_dir"

log_info "Analyzing: $input_file"
python3 "$PYTHON_SCRIPT" "$input_file" -o "$output_file" -v

if [[ -f "$output_file" ]]; then
    log_success "Analysis complete. Results saved to: $output_file"
    
    # Show top candidate
    local top_prompt=$(python3 -c "
```

import json
with open(’$output_file’) as f:
data = json.load(f)
if ‘candidates’ in data and data[‘candidates’]:
print(f"Top candidate ({data[‘candidates’][0][‘confidence’]:.2f}): {data[‘candidates’][0][‘prompt’]}")
else:
print(‘No candidates found’)
“)
echo -e “${GREEN}$top_prompt${NC}”
fi
}

# Batch analysis function

batch_analyze() {
local input_dir=”$1”
local output_dir=”${2:-./batch_results}”

```
if [[ ! -d "$input_dir" ]]; then
    log_error "Input directory not found: $input_dir"
    return 1
fi

activate_env || return 1

mkdir -p "$output_dir"

log_info "Starting batch analysis of: $input_dir"
python3 "$PYTHON_SCRIPT" "$input_dir" --batch -o "$output_dir/batch_results.json" -v

if [[ -f "$output_dir/batch_results.json" ]]; then
    log_success "Batch analysis complete. Results saved to: $output_dir/"
    
    # Generate summary report
    generate_summary_report "$output_dir/batch_results.json" "$output_dir/summary.txt"
fi
```

}

# Generate a human-readable summary report

generate_summary_report() {
local json_file=”$1”
local output_file=”$2”

```
python3 << EOF > "$output_file"
```

import json
from datetime import datetime

with open(’$json_file’) as f:
data = json.load(f)

print(“AI PROMPT INFERENCE ANALYSIS REPORT”)
print(”=” * 50)
print(f”Generated: {datetime.now().strftime(’%Y-%m-%d %H:%M:%S’)}”)
print(f”Total files analyzed: {len(data)}”)
print()

high_confidence = 0
medium_confidence = 0
low_confidence = 0

for file_path, result in data.items():
print(f”File: {file_path}”)
print(f”Type: {result.get(‘file_type’, ‘unknown’)}”)

```
if result.get('candidates'):
    top_candidate = result['candidates'][0]
    confidence = top_candidate['confidence']
    
    if confidence >= 0.8:
        high_confidence += 1
        confidence_label = "HIGH"
    elif confidence >= 0.5:
        medium_confidence += 1
        confidence_label = "MEDIUM"
    else:
        low_confidence += 1
        confidence_label = "LOW"
    
    print(f"Top prompt ({confidence_label} - {confidence:.2f}): {top_candidate['prompt']}")
    print(f"Reasoning: {top_candidate['reasoning']}")
else:
    print("No candidates found")
    low_confidence += 1

print("-" * 30)
```

print()
print(“SUMMARY STATISTICS:”)
print(f”High confidence results (≥0.8): {high_confidence}”)
print(f”Medium confidence results (0.5-0.8): {medium_confidence}”)
print(f”Low confidence results (<0.5): {low_confidence}”)
EOF

```
log_success "Summary report generated: $output_file"
```

}

# Search for AI-generated content in a directory

search_ai_content() {
local search_dir=”$1”
local min_confidence=”${2:-0.7}”
local output_file=”${3:-./ai_content_report.txt}”

```
if [[ ! -d "$search_dir" ]]; then
    log_error "Search directory not found: $search_dir"
    return 1
fi

activate_env || return 1

log_info "Searching for AI-generated content in: $search_dir"
log_info "Minimum confidence threshold: $min_confidence"

# Create temporary batch results
local temp_results="/tmp/ai_search_results.json"
python3 "$PYTHON_SCRIPT" "$search_dir" --batch -o "$temp_results"

# Filter high-confidence results
python3 << EOF > "$output_file"
```

import json

with open(’$temp_results’) as f:
data = json.load(f)

print(“AI-GENERATED CONTENT DETECTION REPORT”)
print(”=” * 50)
print(f”Minimum confidence threshold: $min_confidence”)
print()

ai_files = []

for file_path, result in data.items():
if result.get(‘candidates’):
top_candidate = result[‘candidates’][0]
if top_candidate[‘confidence’] >= $min_confidence:
ai_files.append((file_path, top_candidate))

print(f”Found {len(ai_files)} files likely to be AI-generated:”)
print()

for file_path, candidate in sorted(ai_files, key=lambda x: x[1][‘confidence’], reverse=True):
print(f”File: {file_path}”)
print(f”Confidence: {candidate[‘confidence’]:.2f}”)
print(f”Inferred prompt: {candidate[‘prompt’]}”)
print(f”Evidence: {’, ’.join(candidate[‘evidence’])}”)
print(”-” * 50)
EOF

```
rm -f "$temp_results"
log_success "AI content search complete. Report saved to: $output_file"
```

}

# Monitor directory for new AI-generated content

monitor_directory() {
local watch_dir=”$1”
local alert_threshold=”${2:-0.8}”

```
if ! command -v inotifywait &> /dev/null; then
    log_error "inotifywait not found. Install inotify-tools: sudo apt-get install inotify-tools"
    return 1
fi

if [[ ! -d "$watch_dir" ]]; then
    log_error "Watch directory not found: $watch_dir"
    return 1
fi

log_info "Monitoring directory: $watch_dir"
log_info "Alert threshold: $alert_threshold"
log_info "Press Ctrl+C to stop monitoring"

inotifywait -m -r -e create,moved_to --format '%w%f' "$watch_dir" | while read file; do
    # Check if it's a supported file type
    if [[ "$file" =~ \.(txt|md|jpg|jpeg|png|webp)$ ]]; then
        log_info "New file detected: $file"
        
        # Small delay to ensure file is fully written
        sleep 2
        
        if [[ -f "$file" ]]; then
            activate_env
            
            # Quick analysis
            local temp_result="/tmp/monitor_result.json"
            python3 "$PYTHON_SCRIPT" "$file" -o "$temp_result" 2>/dev/null
            
            if [[ -f "$temp_result" ]]; then
                local confidence=$(python3 -c "
```

import json
try:
with open(’$temp_result’) as f:
data = json.load(f)
if ‘candidates’ in data and data[‘candidates’]:
print(data[‘candidates’][0][‘confidence’])
else:
print(‘0’)
except:
print(‘0’)
“)

```
                if (( $(echo "$confidence >= $alert_threshold" | bc -l) )); then
                    log_warn "ALERT: High-confidence AI-generated content detected!"
                    log_warn "File: $file"
                    log_warn "Confidence: $confidence"
                    
                    # Optional: Send notification, log to syslog, etc.
                    logger "AI content detected: $file (confidence: $confidence)"
                fi
                
                rm -f "$temp_result"
            fi
        fi
    fi
done
```

}

# Performance benchmark

benchmark() {
local test_dir=”${1:-./test_samples}”

```
if [[ ! -d "$test_dir" ]]; then
    log_error "Test directory not found: $test_dir"
    return 1
fi

activate_env || return 1

log_info "Starting performance benchmark..."

local start_time=$(date +%s.%N)
local file_count=0

for file in "$test_dir"/*; do
    if [[ -f "$file" && "$file" =~ \.(txt|md|jpg|jpeg|png|webp)$ ]]; then
        python3 "$PYTHON_SCRIPT" "$file" -o "/tmp/benchmark_$file_count.json" 2>/dev/null
        ((file_count++))
    fi
done

local end_time=$(date +%s.%N)
local duration=$(echo "$end_time - $start_time" | bc)
local avg_time=$(echo "scale=3; $duration / $file_count" | bc)

log_success "Benchmark complete:"
echo "Files processed: $file_count"
echo "Total time: ${duration}s"
echo "Average time per file: ${avg_time}s"

# Cleanup
rm -f /tmp/benchmark_*.json
```

}

# Main command dispatcher

main() {
case “${1:-help}” in
“setup”)
setup_environment
;;
“analyze”)
if [[ $# -lt 2 ]]; then
log_error “Usage: $0 analyze <file> [output_dir]”
exit 1
fi
quick_analyze “$2” “${3:-}”
;;
“batch”)
if [[ $# -lt 2 ]]; then
log_error “Usage: $0 batch <directory> [output_dir]”
exit 1
fi
batch_analyze “$2” “${3:-}”
;;
“search”)
if [[ $# -lt 2 ]]; then
log_error “Usage: $0 search <directory> [min_confidence] [output_file]”
exit 1
fi
search_ai_content “$2” “${3:-0.7}” “${4:-}”
;;
“monitor”)
if [[ $# -lt 2 ]]; then
log_error “Usage: $0 monitor <directory> [alert_threshold]”
exit 1
fi
monitor_directory “$2” “${3:-0.8}”
;;
“benchmark”)
benchmark “${2:-}”
;;
“help”|*)
echo “AI Prompt Inference System”
echo “Usage: $0 <command> [options]”
echo “”
echo “Commands:”
echo “  setup                          - Setup Python environment and dependencies”
echo “  analyze <file> [output_dir]    - Analyze single file”
echo “  batch <dir> [output_dir]       - Batch analyze directory”
echo “  search <dir> [min_conf] [out]  - Search for AI-generated content”
echo “  monitor <dir> [threshold]      - Monitor directory for new AI content”
echo “  benchmark [test_dir]           - Run performance benchmark”
echo “  help                           - Show this help”
echo “”
echo “Examples:”
echo “  $0 setup”
echo “  $0 analyze suspicious_text.txt”
echo “  $0 batch ./media_files ./analysis_results”
echo “  $0 search ./documents 0.8 ./ai_detection_report.txt”
echo “  $0 monitor ./incoming_files 0.9”
;;
esac
}

# Run main function with all arguments

main “$@”
