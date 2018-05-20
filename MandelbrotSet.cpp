#include <SDL2/SDL.h>
#include <iostream>

extern "C" { void countMandelbrotAsm(float imageWidth, float imageHeight, float startX, float endX, float startY, float endY,unsigned int *pixels); }

int main(int argc, char ** argv)
{
    if(argc < 2)
    {
        std::cout<<"Usage: "<<argv[0]<<" <width> <height>\n";
        return 1;
    }
    int imageWidth,imageHeight;
    imageWidth = atoi(argv[1]);
    imageHeight = atoi(argv[2]);
    std::cout<<"Image dimensions: "<<imageWidth<<" x "<<imageHeight<<std::endl;

    bool quit = false;
    SDL_Event event;

    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window * window = SDL_CreateWindow("SDL2 Mandelbrot Set",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, imageWidth, imageHeight, 0);

    SDL_Renderer * renderer = SDL_CreateRenderer(window, -1, 0);
    SDL_Texture * texture = SDL_CreateTexture(renderer,
        SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STATIC, imageWidth, imageHeight);
    Uint32 *pixels = new Uint32[imageWidth * imageHeight];
    srand(time(NULL));
    memset(pixels, 255, imageWidth * imageHeight * sizeof(Uint32)); //set pixel array to white
    float startX = -2.0, startY = -2.0, endX = 2.0, endY = 2.0;

    countMandelbrotAsm(imageWidth,imageHeight,startX,endX,startY,endY,pixels);

    while (!quit)
    {
        SDL_UpdateTexture(texture, NULL, pixels, imageWidth * sizeof(Uint32));
        SDL_WaitEvent(&event);

        switch (event.type)
        {
        case SDL_MOUSEBUTTONUP:
            memset(pixels, 255, imageWidth * imageHeight * sizeof(Uint32)); //set pixel array to white
            if (event.button.button == SDL_BUTTON_LEFT)
            {
                int mouseX = event.motion.x;
                int mouseY = event.motion.y;
                //for(int i=0;i<20;i++)
                    //pixels[mouseY * imageWidth + mouseX + i] = 0xFF4488AA;
                
                std::cout<<"Clicked at X: "<<mouseX<<" | Y: "<<mouseY<<std::endl;

                float widthPart = (float)mouseX/(float)imageWidth;
                float heightPart = (float)mouseY/(float)imageHeight;

                float width = endX - startX;
                std::cout<<"Widthpart: "<<widthPart<<std::endl;
                float widthPartLeft = width*0.15*widthPart;
                startX = startX + widthPartLeft;
                float widthRest = 1.0-widthPart;
                float widthPartRight = width*0.15*widthRest;
                endX = endX - widthPartRight;

                float height = endY - startY;
                std::cout<<"Heightpart: "<<heightPart<<std::endl;
                float heightPartLeft = height*0.15*heightPart;
                startY = startY + heightPartLeft;
                float heightRest = 1.0-heightPart;
                float heightPartRight = height*0.15*heightRest;
                endY = endY - heightPartRight;
                
                countMandelbrotAsm(imageWidth,imageHeight,startX,endX,startY,endY,pixels);
                std::cout<<"New X: "<<startX<<" | "<<endX<<std::endl;
                std::cout<<"New Y: "<<startY<<" | "<<endY<<std::endl;

            }
            else if (event.button.button == SDL_BUTTON_RIGHT)
            {
                startX = -2.0; startY = -2.0;
                endX = 2.0; endY = 2.0;
                countMandelbrotAsm(imageWidth,imageHeight,startX,endX,startY,endY,pixels);
            }

            break;
        case SDL_QUIT:
            quit = true;
            break;
        }

        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    delete[] pixels;
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}