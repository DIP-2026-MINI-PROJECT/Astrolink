%% AstroLink integrated demonstration: FITS input -> DCT channel proxy -> display
% Unit 2 in the existing project is lossy block-DCT coefficient quantization.
% It is NOT bitstream/RF transmission: BER is therefore reported as NaN.
% Requires MATLAB with FITS support (fitsinfo/fitsread) and Image Processing
% Toolbox for dct2/idct2. Tested execution is not asserted by this source file.
clear; close all; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'unit1'));
out = fullfile(root,'results','integrated');
folders = {'reconstructed','scientific_display','pseudocolour','comparisons','graphs','metrics'};
for k=1:numel(folders), p=fullfile(out,folders{k}); if ~isfolder(p), mkdir(p); end, end
names = ["orion","m51"];
block = 8; qstep = 2; pct = [1 99.7]; soft = 0.02;
Image = strings(numel(names),1); MSE=nan(numel(names),1); PSNR_dB=MSE; SSIM=MSE; SNR_dB=MSE; BER=MSE;
for k=1:numel(names)
    name=names(k); Image(k)=name;
    %% Unit 1: read original SCI image and preserve source units
    original=double(load_sci_image(name));
    if isempty(original) || ~ismatrix(original) || ~any(isfinite(original(:)))
        error('Input %s must be a finite, nonempty 2-D science image.',name);
    end
    original(~isfinite(original))=0; [h,w]=size(original);
    %% Unit 2: existing transform-domain quantization (not RF)
    hp=ceil(h/block)*block; wp=ceil(w/block)*block; padded=zeros(hp,wp); padded(1:h,1:w)=original;
    received=zeros(hp,wp);
    for r=1:block:hp
        for c=1:block:wp
            rr=r:r+block-1; cc=c:c+block-1;
            coeff=dct2(padded(rr,cc)); coeffQ=round(coeff/qstep)*qstep;
            received(rr,cc)=idct2(coeffQ);
        end
    end
    %% Unit 3: crop inverse-transform image to original extent
    reconstructed=received(1:h,1:w);
    save(fullfile(out,'reconstructed',name+'_science_arrays.mat'), ...
        'original','reconstructed','block','qstep');
    %% Unit 4: display-only robust asinh stretch, grayscale and pseudocolour
    [dispOrig,limits]=stretch_asinh(original,pct,soft);
    dispRec=stretch_asinh(reconstructed,pct,soft,limits);
    imwrite(mat2gray(reconstructed),fullfile(out,'reconstructed',name+'_reconstructed.png'));
    save_display(dispRec,gray(256),fullfile(out,'scientific_display',name+'_grayscale.png'));
    save_display(dispRec,astro_falsecolor_map(256),fullfile(out,'pseudocolour',name+'_pseudocolour.png'));
    f=figure('Visible','off','Color','w'); tiledlayout(1,4);
    nexttile; imagesc(original); axis image off; colormap(gca,gray); title('Original science');
    nexttile; imagesc(dispOrig,[0 1]); axis image off; colormap(gca,gray); title('Unit 1 display copy');
    nexttile; imagesc(dispRec,[0 1]); axis image off; colormap(gca,gray); title('Reconstructed display');
    nexttile; imagesc(dispRec,[0 1]); axis image off; colormap(gca,astro_falsecolor_map(256)); title('Pseudocolour (display only)');
    exportgraphics(f,fullfile(out,'comparisons',name+'_pipeline.png')); close(f);
    %% Metrics compare original science values against reconstruction only
    err=original-reconstructed; MSE(k)=mean(err(:).^2); peak=max(original(:))-min(original(:));
    if MSE(k)==0, PSNR_dB(k)=Inf; else, PSNR_dB(k)=10*log10(peak^2/MSE(k)); end
    SNR_dB(k)=10*log10(sum(original(:).^2)/max(sum(err(:).^2),realmin));
    SSIM(k)=global_ssim(original,reconstructed); % global SSIM equivalent, documented
    BER(k)=NaN; % no binary encoder/channel/decoder in current project
    fprintf('%s: %d x %d, MSE %.6g, PSNR %.4g dB, global SSIM %.6f, residual SNR %.4g dB, BER N/A\n',name,h,w,MSE(k),PSNR_dB(k),SSIM(k),SNR_dB(k));
end
T=table(Image,MSE,PSNR_dB,SSIM,SNR_dB,BER);
disp(T); writetable(T,fullfile(out,'metrics','metrics.csv')); save(fullfile(out,'metrics','metrics.mat'),'T');
% Keep aggregates separate from per-image rows. NaN BER remains unavailable.
Metric=["MSE";"PSNR_dB";"SSIM";"SNR_dB";"BER"];
Values=[MSE,PSNR_dB,SSIM,SNR_dB,BER];
MeanValue=arrayfun(@(j) mean(Values(:,j),'omitnan'),1:size(Values,2))';
MinValue=arrayfun(@(j) min(Values(:,j),[],'omitnan'),1:size(Values,2))';
MaxValue=arrayfun(@(j) max(Values(:,j),[],'omitnan'),1:size(Values,2))';
Summary=table(Metric,MeanValue,MinValue,MaxValue);
disp(Summary); writetable(Summary,fullfile(out,'metrics','metrics_summary.csv'));
save(fullfile(out,'metrics','metrics.mat'),'Summary','-append');
try, writetable(T,fullfile(out,'metrics','metrics.xlsx')); catch warning('Excel export unavailable; CSV and MAT saved.'); end
metricNames={'PSNR_dB','SSIM','MSE','BER','SNR_dB'};
for j=1:numel(metricNames)
    v=T.(metricNames{j}); f=figure('Visible','off'); bar(categorical(T.Image),v); ylabel(metricNames{j},'Interpreter','none'); xlabel('Input image'); title(['AstroLink metric: ',metricNames{j}]); grid on;
    exportgraphics(f,fullfile(out,'graphs',[metricNames{j},'.png'])); close(f);
end
fprintf('Distinct source images run: %d. Dataset has fewer than required 10. See Documentation/Results_Analysis.md.\n',numel(names));

function [y,lim]=stretch_asinh(x,pct,soft,lim)
v=x(isfinite(x)); if nargin<4 || isempty(lim), lim=[percentile(v,pct(1)),percentile(v,pct(2))]; end
if lim(2)<=lim(1), lim(2)=lim(1)+eps(max(1,abs(lim(1)))); end
z=min(max((x-lim(1))/(lim(2)-lim(1)),0),1); a=max(soft,eps); y=asinh(z/a)/asinh(1/a); y=min(max(y,0),1);
end
function q=percentile(x,p)
x=sort(x(:)); t=1+(numel(x)-1)*p/100; lo=floor(t); hi=ceil(t); q=x(lo)+(t-lo)*(x(hi)-x(lo));
end
function s=global_ssim(a,b)
% Global luminance/contrast/structure SSIM, using data-derived range.
L=max(a(:))-min(a(:)); if L==0, L=1; end; C1=(0.01*L)^2; C2=(0.03*L)^2;
ma=mean(a(:)); mb=mean(b(:)); va=mean((a(:)-ma).^2); vb=mean((b(:)-mb).^2); covar=mean((a(:)-ma).*(b(:)-mb));
s=((2*ma*mb+C1)*(2*covar+C2))/((ma^2+mb^2+C1)*(va+vb+C2));
end
function save_display(x,map,path)
f=figure('Visible','off','Color','w'); ax=axes(f); imagesc(ax,x,[0 1]); axis(ax,'image','off'); colormap(ax,map); colorbar(ax); exportgraphics(f,path); close(f);
end
