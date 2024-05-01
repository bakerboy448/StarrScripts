def merge_directories(src, dst):
    """
    Recursively merges directories from src to dst without overwriting existing files.
    """
    for item in os.listdir(src):
        src_path = os.path.join(src, item)
        dst_path = os.path.join(dst, item)
        
        if os.path.isdir(src_path):
            # If it's a directory, recurse into it
            if not os.path.exists(dst_path):
                os.makedirs(dst_path)
                logging.info(f"Directory created: {dst_path}")
            merge_directories(src_path, dst_path)
        else:
            # It's a file, check if it exists in the destination
            if not os.path.exists(dst_path):
                # Move the file atomically if on the same filesystem
                shutil.move(src_path, dst_path)
                logging.info(f"File moved: {src_path} to {dst_path}")
            else:
                logging.info(f"File skipped (already exists): {dst_path}")

def atomic_moves(source_directories, target_directory):
    """
    Handles atomic moving from multiple source directories to a single target directory.
    """
    for src in source_directories:
        logging.info(f"Processing source directory: {src}")
        try:
            # Start the merging process for each source directory
            merge_directories(src, target_directory)
        except Exception as e:
            logging.error(f"Error during moving process from {src}: {e}")

# Example use case (commented out for safety):
# source_dirs = ['/mnt/data/media/tv-slade', '/mnt/data/media/tv-tmp']
# target_dir = '/mnt/data/media/tv'
# atomic_moves(source_dirs, target_dir)
