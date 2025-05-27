-- Create policies for the podcast-files bucket
CREATE POLICY "Allow authenticated users to upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'podcast-files' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow users to update their own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'podcast-files' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

CREATE POLICY "Allow public to read files"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'podcast-files');

CREATE POLICY "Allow users to delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'podcast-files' AND
  auth.uid()::text = (storage.foldername(name))[2]
); 